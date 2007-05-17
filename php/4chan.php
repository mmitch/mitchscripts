<?
// $Id: 4chan.php,v 1.4 2007-05-17 13:07:48 mitch Exp $
// cookie handling
//if (isset($comic) && isset($id) && isset($tag)) {
//  setcookie("lastVisited[$tag]", $id, time()+( 3600 * 24 * 365 * 5));
//}
?>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
  <head>
    <title>Mitchs 4chanbrowser irssi plugin</title>
  </head>

  <body>

    <h1>Mitchs 4chanbrowser irssi plugin</h1>

    <table>
      <tr>
        <th>File</th>
        <th>Chan</th>
        <th>Board</th>
        <th>Nick</th>
        <th>Channel</th>
        <th>Date</th>
      </tr>

<?

$cachedir='/home/mitch/pub/4chan';

$find = popen("ls -t $cachedir", "r");
if ($find) {
  while (! feof($find)) {
    $file = rtrim(fgets($find, 8192)); // max 8k per line
    $entry = array();
    if (preg_match('/\.idx$/', $file)) {
      $idx = fopen("$cachedir/$file", 'r');
      if ($idx) {
	while (! feof($idx)) {
	  $line = rtrim(fgets($idx, 8192)); // max 8k per line
	  list($key, $value) = split("\t", $line);
	  $entry[$key] = $value;
	}
	fclose($idx);
      }
      if (!$entry['CHAN']) {
	$entry['CHAN'] = '4chan';
      }
      echo "      <tr>\n";
      echo "        <td><a href=\"/4chan/", rawurlencode($entry['FILE']), "\">{$entry['FILE']}</a> (<a href=\"{$entry['URL']}\">orig</a>)</td>\n";
      echo "        <td>{$entry['CHAN']}</td>\n";
      echo "        <td>/{$entry['BOARD']}/</td>\n";
      echo "        <td>{$entry['NICK']}</td>\n";
      echo "        <td>{$entry['CHANNEL']}</td>\n";
      echo "        <td>{$entry['TIME']}</td>\n";
      echo "      </tr>\n";
    }
  }
  pclose($find);
}
?>
    </table>

    <hr>
    <address><a href="mailto:mitch@cgarbs.de">Christian Garbs [Master Mitch]</a></address>
    <p><small>$Revision: 1.4 $<br>$Date: 2007-05-17 13:07:48 $</small></p>
  </body>
</html>
