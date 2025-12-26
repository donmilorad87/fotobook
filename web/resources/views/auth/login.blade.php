@extends('layouts.auth')

@section('title', 'Login')

@section('content')
<form method="POST" action="{{ route('login') }}" class="auth-form">
    @csrf

    <div class="form-group">
        <label for="email" class="form-label">Email</label>
        <input type="email" name="email" id="email" class="form-input" value="{{ old('email') }}" required autofocus>
        @error('email')
            <p class="form-error">{{ $message }}</p>
        @enderror
    </div>

    <div class="form-group">
        <label for="password" class="form-label">Password</label>
        <input type="password" name="password" id="password" class="form-input" required>
        @error('password')
            <p class="form-error">{{ $message }}</p>
        @enderror
    </div>

    <div class="form-group">
        <label style="display: flex; align-items: center; gap: 8px; cursor: pointer;">
            <input type="checkbox" name="remember" class="form-checkbox" {{ old('remember') ? 'checked' : '' }}>
            <span style="font-size: 0.875rem;">Remember me</span>
        </label>
    </div>

    <button type="submit" class="btn btn-primary">Login</button>
</form>

<div class="auth-links">
    <p>Don't have an account? <a href="{{ route('register') }}">Register</a></p>
</div>
@endsection
