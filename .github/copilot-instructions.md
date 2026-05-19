# PHP Internet Speed Tester - Development Instructions

## Project Overview

This is a PHP-based internet speed tester application that runs locally on your machine. It tests:
- **Ping/Latency**: Response time to the server
- **Download Speed**: How fast data can be downloaded
- **Upload Speed**: How fast data can be uploaded

## Development Setup

### Prerequisites

- PHP 7.0 or higher (built-in web server required)
- A modern web browser (Chrome, Firefox, Edge, Safari)
- Basic understanding of PHP and JavaScript

### Project Structure

```
network tester/
├── index.php                 # Router - directs requests to appropriate files
├── public/
│   ├── index.html           # Main HTML interface
│   ├── styles.css           # CSS styling
│   └── app.js               # Frontend JavaScript/testing logic
├── src/
│   └── api/
│       ├── ping.php         # Ping endpoint (latency test)
│       ├── download-test.php # Download speed test endpoint
│       └── upload-test.php   # Upload speed test endpoint
└── README.md                # User documentation

```

### Key Files

#### Frontend (JavaScript-based testing)
- **public/app.js**: Contains the main testing logic
  - `startTest()`: Initiates all three tests sequentially
  - `testPing()`: Measures latency
  - `testDownloadSpeed()`: Measures download speed
  - `testUploadSpeed()`: Measures upload speed

#### Backend (PHP API endpoints)
- **index.php**: Router that handles all requests and directs them to appropriate endpoints
- **src/api/ping.php**: Returns quickly to measure ping time
- **src/api/download-test.php**: Sends random data for download test
- **src/api/upload-test.php**: Receives data for upload test

### Running the Application

1. Open PowerShell/Terminal in the project directory
2. Run: `php -S localhost:8000`
3. Open browser to: `http://localhost:8000`

### Development Workflow

When making changes:
1. Edit frontend files in `public/` for UI changes
2. Edit backend files in `src/api/` for API logic changes
3. Refresh browser to see changes (no server restart needed for most changes)
4. Check browser console (F12) for JavaScript errors
5. Check terminal for PHP errors

### Common Tasks

**Add a new speed test type:**
1. Create new file in `src/api/test-name.php`
2. Add route in `index.php`
3. Add JavaScript function in `public/app.js`
4. Add UI elements in `public/index.html`

**Modify test parameters:**
- Download/upload test duration: Edit `testDuration` in `public/app.js` (currently 10000ms)
- Data chunk size: Edit `chunkSize` in `src/api/download-test.php`
- File size limits: Edit size limits in `src/api/download-test.php`

**Improve UI:**
- Modify colors and styles in `public/styles.css`
- Update layout in `public/index.html`
- Add animations in `public/app.js`

### Testing

#### Manual Testing
1. Run all three tests and verify results are reasonable
2. Test on different network conditions
3. Test in different browsers
4. Test on mobile devices

#### Performance Testing
- Download tests should complete in ~10 seconds
- Upload tests should complete in ~10 seconds
- Ping test should complete in <1 second

### Debugging

**JavaScript Errors:**
- Open browser F12 → Console tab
- Check for any red error messages

**PHP Errors:**
- Check terminal where `php -S` is running
- Look for PHP warnings or fatal errors

**Network Issues:**
- Open browser F12 → Network tab
- Check request/response details for API calls
- Verify status codes (should be 200)

### Performance Optimization

Current optimizations:
- Chunked data transfer for large files
- Random data generation (faster than real file I/O)
- Immediate flush() calls to send data to browser
- Minimal session overhead

Potential improvements:
- Cache test data
- Use compression for download tests
- Implement multi-threaded uploads/downloads
- Add connection pooling

### Deployment

For local use:
- Use `php -S localhost:8000` (development server)

For production (NOT recommended for internet exposure):
- Use Apache or Nginx
- Implement authentication
- Add rate limiting
- Sanitize all inputs
- Use HTTPS

### Browser Compatibility

- Chrome/Edge: Full support
- Firefox: Full support  
- Safari: Full support
- Mobile browsers: Full support

### Limitations

- Tests are limited by actual network speed
- Cannot test speeds faster than your internet connection
- Upload tests limited by PHP post_max_size and upload_max_filesize
- Download tests limited by available server bandwidth

---

**Last Updated:** May 19, 2026
