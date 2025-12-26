<?php

namespace App\Http\Controllers;

use Illuminate\Http\Response;
use Illuminate\Support\Facades\Cache;

class ImageProxyController extends Controller
{
    /**
     * Proxy Google Drive images to avoid CORS issues.
     * Mimics browser request to reliably fetch images.
     * Caches images for 1 hour to reduce API calls.
     */
    public function show(string $fileId): Response
    {
        $cacheKey = "gdrive_image_{$fileId}";

        $imageData = Cache::remember($cacheKey, 3600, function () use ($fileId) {
            return $this->fetchGoogleDriveImage($fileId);
        });

        if ($imageData === null) {
            abort(404, 'Image not found');
        }

        return response(base64_decode($imageData['body']))
            ->header('Content-Type', $imageData['content_type'])
            ->header('Cache-Control', 'public, max-age=86400');
    }

    /**
     * Fetch image from Google Drive using cURL.
     * Tries multiple URL formats for reliability.
     */
    private function fetchGoogleDriveImage(string $fileId): ?array
    {
        // Try multiple URL formats - Google changes these periodically
        $urls = [
            "https://drive.google.com/thumbnail?id={$fileId}&sz=w1920",
            "https://lh3.googleusercontent.com/d/{$fileId}=w1920",
            "https://drive.google.com/uc?export=view&id={$fileId}",
        ];

        foreach ($urls as $url) {
            $result = $this->tryFetchImage($url);
            if ($result !== null) {
                return $result;
            }
        }

        \Log::warning("Google Drive image fetch failed for all URLs: {$fileId}");
        return null;
    }

    /**
     * Attempt to fetch image from a single URL.
     */
    private function tryFetchImage(string $url): ?array
    {
        $ch = curl_init();

        curl_setopt_array($ch, [
            CURLOPT_URL => $url,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_FOLLOWLOCATION => true,
            CURLOPT_MAXREDIRS => 10,
            CURLOPT_TIMEOUT => 30,
            CURLOPT_CONNECTTIMEOUT => 10,
            CURLOPT_SSL_VERIFYPEER => true,
            CURLOPT_USERAGENT => 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)',
            CURLOPT_HTTPHEADER => [
                'Accept: image/*,*/*;q=0.8',
            ],
        ]);

        $body = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $contentType = curl_getinfo($ch, CURLINFO_CONTENT_TYPE);
        $error = curl_error($ch);

        curl_close($ch);

        if ($error || $httpCode !== 200 || empty($body)) {
            return null;
        }

        // Verify it's actually an image (not an HTML error page)
        if (strpos($contentType, 'text/html') !== false) {
            return null;
        }

        return [
            'body' => base64_encode($body),
            'content_type' => $contentType ?: 'image/jpeg',
        ];
    }
}
