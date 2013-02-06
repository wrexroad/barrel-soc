 <?php
$data = $_POST['imageData'];

//removing the "data:image/png;base64," part
$uri =  substr($data,strpos($data,",")+1);

$fileClient = $_POST['imageName'];

$fileServer = $fileClient;
$fileServer .= substr(time(),-3);
$fileServer .= substr($_SERVER['REMOTE_ADDR'],-3);

//save file to server
file_put_contents($fileServer, base64_decode($uri));

//if file saved sucessfully, force download dialog
if (file_exists($fileServer)) {
    header('Content-Description: File Transfer');
    header('Content-Type: image/png');
    header('Content-Disposition: attachment; filename='.basename($fileClient));
    header('Content-Transfer-Encoding: binary');
    header('Expires: 0');
    header('Cache-Control: must-revalidate, post-check=0, pre-check=0');
    header('Pragma: public');
    header('Content-Length: ' . filesize($fileServer));
    ob_clean();
    flush();
    readfile($fileServer);
    unlink($fileServer);
    exit;
}
 ?> 
