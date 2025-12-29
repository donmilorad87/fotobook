<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Str;

class User extends Authenticatable
{
    use HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'password',
        'google_access_token',
        'google_refresh_token',
        'google_token_expires_at',
        'google_email',
        'api_token',
    ];

    protected $hidden = [
        'password',
        'remember_token',
        'google_access_token',
        'google_refresh_token',
        'api_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'google_token_expires_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    /**
     * Get galleries owned by this user.
     */
    public function galleries(): HasMany
    {
        return $this->hasMany(Gallery::class);
    }

    /**
     * Check if user has connected Google account.
     */
    public function isGoogleConnected(): bool
    {
        return !empty($this->google_access_token);
    }

    /**
     * Generate a new API token for desktop app authentication.
     * Returns the plain token (store this in desktop app).
     * The hashed version is stored in the database.
     */
    public function generateApiToken(): string
    {
        $plainToken = Str::random(80);
        $this->api_token = hash('sha256', $plainToken);
        $this->save();

        return $plainToken;
    }

    /**
     * Revoke the current API token.
     */
    public function revokeApiToken(): void
    {
        $this->api_token = null;
        $this->save();
    }

    /**
     * Get the user's initials for avatar display.
     */
    public function getInitialsAttribute(): string
    {
        $words = explode(' ', $this->name);
        $initials = '';

        foreach (array_slice($words, 0, 2) as $word) {
            $initials .= strtoupper(substr($word, 0, 1));
        }

        return $initials;
    }
}
