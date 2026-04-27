# index.html Must Exist in Every Web Directory

## Rule
Every Layer 8 project's web directory (`go/<project>/ui/web/`) MUST include an `index.html` file that redirects to `login.html`. Without it, the web server returns a 404 when users navigate to the root URL.

## Template
```html
<!--
© 2025 Sharon Aicler (saichler@gmail.com)

Layer 8 Ecosystem is licensed under the Apache License, Version 2.0.
-->
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="refresh" content="0; url=login.html">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PROJECT_TITLE</title>
    <script>
        window.location.href = 'login.html';
    </script>
</head>
<body>
    <p>Redirecting to <a href="login.html">PROJECT_TITLE</a>...</p>
</body>
</html>
```

Replace `PROJECT_TITLE` with the project's display name (e.g., "Spring Back Sell", "L8ID").

## When to Create
When setting up the web directory for a new project — at the same time as `login.html`, `app.html`, and `login.json`.
