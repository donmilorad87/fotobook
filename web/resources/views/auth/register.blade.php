@extends('layouts.auth')

@section('title', 'Register')

@section('content')
<form method="POST" action="{{ route('register') }}" class="auth-form">
    @csrf

    <div class="form-group">
        <label for="name" class="form-label">Name</label>
        <input type="text" name="name" id="name" class="form-input" value="{{ old('name') }}" required autofocus>
        @error('name')
            <p class="form-error">{{ $message }}</p>
        @enderror
    </div>

    <div class="form-group">
        <label for="email" class="form-label">Email</label>
        <input type="email" name="email" id="email" class="form-input" value="{{ old('email') }}" required>
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
        <label for="password_confirmation" class="form-label">Confirm Password</label>
        <input type="password" name="password_confirmation" id="password_confirmation" class="form-input" required>
    </div>

    <button type="submit" class="btn btn-primary">Register</button>
</form>

<div class="auth-links">
    <p>Already have an account? <a href="{{ route('login') }}">Login</a></p>
</div>
@endsection
