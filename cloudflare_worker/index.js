/**
 * Cloudflare Worker: Photo Finder Upload & ZIP Extractor
 * 
 * Features:
 * 1. Handles CORS for the Admin Panel.
 * 2. ZIP extraction using 'fflate'.
 * 3. Uploads images to Cloudflare R2.
 * 4. Inserts photo metadata into Supabase.
 */

import { unzipSync } from 'fflate';

export default {
    async fetch(request, env) {
        const url = new URL(request.url);

        // ─── 1. Handle CORS Preflight ─────────────────────────────────────────────
        if (request.method === "OPTIONS") {
            return new Response(null, {
                headers: {
                    "Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Methods": "POST, OPTIONS",
                    "Access-Control-Allow-Headers": "Content-Type",
                },
            });
        }

        if (request.method !== "POST") {
            return new Response("Method Not Allowed", { status: 405 });
        }

        try {
            const formData = await request.formData();
            const file = formData.get("file");
            const eventId = formData.get("event_id");

            if (!file || !eventId) {
                return new Response("Missing file or event_id", { status: 400 });
            }

            const results = [];
            const buffer = await file.arrayBuffer();
            const uint8 = new Uint8Array(buffer);

            // ─── 2. Identify and Process File ──────────────────────────────────────
            if (file.name.endsWith('.zip')) {
                // ZIP Extraction
                const unzipped = unzipSync(uint8);

                for (const [filename, content] of Object.entries(unzipped)) {
                    // Skip directories and non-images
                    if (filename.includes('__MACOSX') || filename.endsWith('/') || !/\.(jpg|jpeg|png|webp)$/i.test(filename)) {
                        continue;
                    }

                    const r2Path = await uploadToR2AndNotifySupabase(
                        content,
                        eventId,
                        filename,
                        env
                    );
                    results.push(r2Path);
                }
            } else {
                // Single Image Upload
                const r2Path = await uploadToR2AndNotifySupabase(
                    uint8,
                    eventId,
                    file.name,
                    env
                );
                results.push(r2Path);
            }

            return new Response(JSON.stringify({
                success: true,
                count: results.length,
                files: results
            }), {
                headers: {
                    "Content-Type": "application/json",
                    "Access-Control-Allow-Origin": "*",
                },
            });

        } catch (err) {
            console.error(err);
            return new Response(JSON.stringify({ error: err.message }), {
                status: 500,
                headers: {
                    "Content-Type": "application/json",
                    "Access-Control-Allow-Origin": "*",
                },
            });
        }
    },
};

/**
 * Uploads to R2 and inserts into Supabase
 */
async function uploadToR2AndNotifySupabase(content, eventId, originalName, env) {
    const extension = originalName.split('.').pop();
    const filename = `${eventId}/${crypto.randomUUID()}.${extension}`;

    // 1. Upload to R2
    await env.MY_BUCKET.put(filename, content, {
        httpMetadata: { contentType: `image/${extension === 'jpg' ? 'jpeg' : extension}` },
    });

    // 2. Notify Supabase
    const supabaseResponse = await fetch(`${env.SUPABASE_URL}/rest/v1/photos`, {
        method: "POST",
        headers: {
            "apikey": env.SUPABASE_KEY,
            "Authorization": `Bearer ${env.SUPABASE_KEY}`,
            "Content-Type": "application/json",
            "Prefer": "return=minimal"
        },
        body: JSON.stringify({
            event_id: eventId,
            image_url: filename,
            thumbnail_url: filename, // Simplified for now
        }),
    });

    if (!supabaseResponse.ok) {
        throw new Error(`Supabase error: ${await supabaseResponse.text()}`);
    }

    return filename;
}
