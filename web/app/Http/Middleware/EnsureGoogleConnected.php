<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureGoogleConnected
{
    /**
     * Handle an incoming request.
     * Redirects to Google connect page if user hasn't connected their Google account.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (!$user) {
            return redirect()->route('login');
        }

        if (!$user->isGoogleConnected()) {
            return redirect()->route('google.connect')
                ->with('warning', 'Please connect your Google account to continue.');
        }

        return $next($request);
    }
}
