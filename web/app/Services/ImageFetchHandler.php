<?php

namespace App\Services;

use Illuminate\Support\Facades\Log;

class ImageFetchHandler
{
    /**
     * Fetch image from Google Drive.
     * Returns array with base64-encoded body and content type, or null on failure.
     */
    public function fetch(string $fileId): ?array
    {
        $urls = [
            "https://drive.google.com/thumbnail?id={$fileId}&sz=w1920",
            "https://lh3.googleusercontent.com/d/{$fileId}=w1920",
            "https://drive.google.com/uc?export=view&id={$fileId}",
        ];

        $urlCount = count($urls);
        for ($i = 0; $i < $urlCount; $i++) {
            $result = $this->tryFetchImage($urls[$i]);
            if ($result !== null) {
                return $result;
            }
        }

        Log::warning("Google Drive image fetch failed for all URLs: {$fileId}");
        return null;
    }

    /**
     * Attempt to fetch image from a single URL.
     */
    private function tryFetchImage(string $url): ?array
    {
        $ch = curl_init();

        if ($ch === false) {
            return null;
        }

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

        if ($error !== '' || $httpCode !== 200 || empty($body)) {
            return null;
        }

        if (strpos($contentType, 'text/html') !== false) {
            return null;
        }

        return [
            'body' => base64_encode($body),
            'content_type' => $contentType ?: 'image/jpeg',
            'success' => true,
        ];
    }
}
