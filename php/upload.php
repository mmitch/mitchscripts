<html>
<head>
<title>Uploader</title>
<style>
.error {
    font-weight: bold;
    color: red;
}
form {
    margin-bottom: 2em;
}

form, form * {
    font-size: 80%;
    
}
img {
    display: block;
    margin: auto;
}
</style>
</head>
<body>

<?php

# echo '<pre>'; print_r($_FILES); echo '</pre>';

function error($text) {
    echo '<p class="error">'.$text.'</p>';
    $upload_ok = 0;
}

function parse_upload() {

    $flag_file   = '/home/mitch/pub/uploader/FLAG';
    $target_file = '/home/mitch/pub/uploader/img.jpg';

    if (! file_exists($flag_file)) {
        error('File upload disabled!');
        return;
    }

    if (! isset($_FILES["image"]["tmp_name"])) {
        error('No file in upload!');
        return;
    }

    if (! $_FILES["image"]["tmp_name"]) {
        error('No file in upload!');
        return;
    }

    if (! getimagesize($_FILES["image"]["tmp_name"])) {
        error('Upload is no picture!');
        return;
    }

    if ($_FILES["image"]["size"] > 1500000) {
        error('Upload is too large!');
        return;
    }

    if (pathinfo($_FILES["image"]["name"], PATHINFO_EXTENSION) != "jpg") {
        error('Upload only .jpg!');
        return;
    }

    if (! move_uploaded_file($_FILES["image"]["tmp_name"], $target_file)) {
        error('Unspecified error occured in move_uploaded_file()!');
        return;
    }
}

if (isset($_POST["submit"])) {
    parse_upload();
}

?>

<form action="upload.php" method="post" enctype="multipart/form-data">
     <input type="file" name="image" id="image">
     <input type="submit" value="Upload Image" name="submit">
</form>

<div class="center">
    <img src="img.jpg">
</div>
    
</body>
</html>