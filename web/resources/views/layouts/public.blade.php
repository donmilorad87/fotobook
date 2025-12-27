<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <meta name="assets-version" content="@assetsVersion">

    <title>@yield('title', 'Gallery') - {{ config('app.name') }}</title>

    @vite(['resources/css/app.scss', 'resources/js/app.js', 'resources/js/gallery-selection.js', 'resources/js/lightbox.js', 'resources/js/google-image-loader.js'])
    <script src="{{ asset('js/image-cache-service.js') }}?v={{ config('app.assets_version') }}"></script>
</head>
<body>
    <div class="public-layout">
        @yield('content')
    </div>
</body>
</html>
