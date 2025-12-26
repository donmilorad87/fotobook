@extends('layouts.app')

@section('title', 'Profile')
@section('page-title', 'Profile Settings')

@section('content')
<div class="profile-page">
    <div class="profile-section">
        <div class="profile-section-header">
            <h2>Profile Information</h2>
            <p>Update your account information.</p>
        </div>
        <form action="{{ route('profile.update') }}" method="POST">
            @csrf
            @method('PUT')
            <div class="profile-section-body">
                <div class="profile-form-row">
                    <div class="form-group" style="margin-bottom: 0;">
                        <label for="name" class="form-label">Name</label>
                        <input type="text" name="name" id="name" class="form-input" value="{{ old('name', $user->name) }}" required>
                        @error('name')
                            <p class="form-error">{{ $message }}</p>
                        @enderror
                    </div>
                    <div class="form-group" style="margin-bottom: 0;">
                        <label for="email" class="form-label">Email</label>
                        <input type="email" name="email" id="email" class="form-input" value="{{ old('email', $user->email) }}" required>
                        @error('email')
                            <p class="form-error">{{ $message }}</p>
                        @enderror
                    </div>
                </div>
            </div>
            <div class="profile-actions">
                <span></span>
                <button type="submit" class="btn btn-primary">Save Changes</button>
            </div>
        </form>
    </div>

    <div class="profile-section">
        <div class="profile-section-header">
            <h2>Change Password</h2>
            <p>Update your password to keep your account secure.</p>
        </div>
        <form action="{{ route('profile.update') }}" method="POST">
            @csrf
            @method('PUT')
            <input type="hidden" name="name" value="{{ $user->name }}">
            <input type="hidden" name="email" value="{{ $user->email }}">
            <div class="profile-section-body">
                <div class="form-group">
                    <label for="current_password" class="form-label">Current Password</label>
                    <input type="password" name="current_password" id="current_password" class="form-input">
                    @error('current_password')
                        <p class="form-error">{{ $message }}</p>
                    @enderror
                </div>
                <div class="profile-form-row">
                    <div class="form-group" style="margin-bottom: 0;">
                        <label for="new_password" class="form-label">New Password</label>
                        <input type="password" name="new_password" id="new_password" class="form-input">
                        @error('new_password')
                            <p class="form-error">{{ $message }}</p>
                        @enderror
                    </div>
                    <div class="form-group" style="margin-bottom: 0;">
                        <label for="new_password_confirmation" class="form-label">Confirm New Password</label>
                        <input type="password" name="new_password_confirmation" id="new_password_confirmation" class="form-input">
                    </div>
                </div>
            </div>
            <div class="profile-actions">
                <span></span>
                <button type="submit" class="btn btn-primary">Update Password</button>
            </div>
        </form>
    </div>

    <div class="profile-section">
        <div class="profile-section-header">
            <h2>Google Drive Connection</h2>
            <p>Manage your Google Drive connection for photo storage.</p>
        </div>
        <div class="profile-section-body">
            @if($user->isGoogleConnected())
                <div class="google-connection-status google-connection-status--connected">
                    <div class="connection-info">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" style="color: #22c55e;">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                        <div class="connection-text">
                            <h4>Connected</h4>
                            <p>Your Google Drive is connected and ready for uploads.</p>
                        </div>
                    </div>
                    <form action="{{ route('google.disconnect') }}" method="POST">
                        @csrf
                        <button type="submit" class="btn btn-secondary btn-sm">Disconnect</button>
                    </form>
                </div>
            @else
                <div class="google-connection-status google-connection-status--disconnected">
                    <div class="connection-info">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" style="color: #f59e0b;">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                        </svg>
                        <div class="connection-text">
                            <h4>Not Connected</h4>
                            <p>Connect your Google account to enable photo uploads.</p>
                        </div>
                    </div>
                    <a href="{{ route('google.redirect') }}" class="btn btn-primary btn-sm">Connect</a>
                </div>
            @endif
        </div>
    </div>
</div>
@endsection
