<?php

namespace App\Http\Controllers;

use Illuminate\View\View;

class DownloadController extends Controller
{
    /**
     * Show the desktop app download page.
     */
    public function index(): View
    {
        // Detect user's operating system for recommended download
        $userAgent = request()->header('User-Agent', '');
        $os = $this->detectOS($userAgent);

        return view('download.index', [
            'detectedOS' => $os,
        ]);
    }

    /**
     * Detect operating system from user agent.
     */
    private function detectOS(string $userAgent): string
    {
        if (stripos($userAgent, 'Windows') !== false) {
            return 'windows';
        }

        if (stripos($userAgent, 'Mac') !== false) {
            return 'macos';
        }

        if (stripos($userAgent, 'Linux') !== false) {
            return 'linux';
        }

        return 'unknown';
    }
}
