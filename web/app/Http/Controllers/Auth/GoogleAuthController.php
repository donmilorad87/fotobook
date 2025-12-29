<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\View\View;
use Laravel\Socialite\Facades\Socialite;

class GoogleAuthController extends Controller
{
    /**
     * Show the Google connect page.
     */
    public function show(): View|RedirectResponse
    {
        $user = Auth::user();

        if ($user === null) {
            return redirect()->route('login');
        }

        if ($user->isGoogleConnected()) {
            return redirect()->route('dashboard')
                ->with('info', 'Your Google account is already connected.');
        }

        return view('google.connect');
    }

    /**
     * Redirect to Google OAuth.
     */
    public function redirect(): RedirectResponse
    {
        return Socialite::driver('google')
            ->scopes(['https://www.googleapis.com/auth/drive'])
            ->with(['access_type' => 'offline', 'prompt' => 'consent'])
            ->redirect();
    }

    /**
     * Handle Google OAuth callback.
     */
    public function callback(Request $request): RedirectResponse
    {
        $user = Auth::user();

        if ($user === null) {
            return redirect()->route('login')
                ->with('error', 'You must be logged in to connect Google.');
        }

        if ($request->has('error')) {
            return redirect()->route('google.connect')
                ->with('error', 'Failed to connect Google account: ' . $request->get('error'));
        }

        try {
            $googleUser = Socialite::driver('google')->user();

            $user->update([
                'google_access_token' => $googleUser->token,
                'google_refresh_token' => $googleUser->refreshToken,
                'google_token_expires_at' => now()->addSeconds($googleUser->expiresIn),
                'google_email' => $googleUser->email,
            ]);

            return redirect()->route('dashboard')
                ->with('success', 'Google Drive connected: ' . $googleUser->email);
        } catch (\Exception $e) {
            return redirect()->route('google.connect')
                ->with('error', 'Failed to connect Google account: ' . $e->getMessage());
        }
    }

    /**
     * Disconnect Google account.
     */
    public function disconnect(): RedirectResponse
    {
        $user = Auth::user();

        if ($user === null) {
            return redirect()->route('login');
        }

        $user->update([
            'google_access_token' => null,
            'google_refresh_token' => null,
            'google_token_expires_at' => null,
            'google_email' => null,
        ]);

        return redirect()->route('google.connect')
            ->with('success', 'Google account disconnected.');
    }
}
