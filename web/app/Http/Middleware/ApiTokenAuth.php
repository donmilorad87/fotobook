<?php

namespace App\Http\Middleware;

use App\Models\User;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class ApiTokenAuth
{
    /**
     * Handle an incoming request.
     * Validates Bearer token from Authorization header for API requests.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $token = $request->bearerToken();

        if (!$token) {
            return response()->json([
                'error' => 'Unauthorized',
                'message' => 'No API token provided.',
            ], 401);
        }

        // Hash the provided token and compare with stored hash
        $hashedToken = hash('sha256', $token);
        $user = User::where('api_token', $hashedToken)->first();

        if (!$user) {
            return response()->json([
                'error' => 'Unauthorized',
                'message' => 'Invalid API token.',
            ], 401);
        }

        // Check if Google is connected (required for API operations)
        if (!$user->isGoogleConnected()) {
            return response()->json([
                'error' => 'Forbidden',
                'message' => 'Google account not connected. Please connect via web app first.',
            ], 403);
        }

        // Set the authenticated user for the request
        $request->setUserResolver(fn () => $user);

        return $next($request);
    }
}
