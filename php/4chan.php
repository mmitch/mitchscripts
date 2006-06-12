<?
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
      echo "      <tr>\n";
      echo "        <td><a href=\"/4chan/{$entry['FILE']}\">{$entry['FILE']}</a> (<a href=\"{$entry['URL']}\">orig</a>)</td>\n";
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
    <p><small>$Revision: 1.2 $<br>$Date: 2006-06-12 21:14:59 $</small></p>
  </body>
</html>
