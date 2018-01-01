$XMLfile="/home/luisfeliz/Downloads/playlist.xml"                           
#$mylist.node.node[1].node 
#http://:lf1219@localhost:8080

#This XML reader is easier on memory requirements, and can handle large documents
$f = [System.Xml.XmltextReader]::Create($XMLfile)
$f.read()

$oArray=@()

$f.ReadToFollowing("node")

[xml]$xml=$f.ReadOuterXml()

     #Take care of the root leafs first
	$xml.node.node[1].leaf | foreach {

	if ($($_.'name' -notlike "*.cdg*")) {
	$oarray += new-object PSObject -property ([ordered]@{

	  #Select-XML allows you to address XML elements as they appear on the file
	  "SongName"    = $_.'name'
	  "SongURL"     = $_.'uri'
	  "SongID"   = $_.'id'

	}) #new-object
      }#if
   }#for


$level="node"

while ($done -ne $True) {

$done=$true

     #Take care of the root leafs first
     if ($xml.node.node[1].$level.leaf -ne $null) {

	$xml.node.node[1].leaf | foreach {

	if ($($_.'name' -notlike "*.cdg*")) {
	$oarray += new-object PSObject -property ([ordered]@{

	  #Select-XML allows you to address XML elements as they appear on the file
	  "SongName"    = $_.'name'
	  "SongURL"     = $_.'uri'
	  "SongID"   = $_.'id'

	}) #new-object
      }#if 
    }#for

    }#if

    #and now subfolders and their leafs
    if ($xml.node.node[1].$level -ne $null) {
	write-host $xml.node.node[1].$level.name
     $xml.node.node[1].$level.leaf | foreach {

	if ($($_.'name' -notlike "*.cdg*")) {
	$oarray += new-object PSObject -property ([ordered]@{

	  #Select-XML allows you to address XML elements as they appear on the file
	  "SongName"    = $_.'name'
	  "SongURL"     = $_.'uri'
	  "SongID"   = $_.'id'

	}) #new-object
      }#if
     }#for
    $done=$false
    }#if

$level=$level+".node"
	
}

# Ok, lets work on making the static pages


$script=@"
<SCRIPT>

function loadurl( url) {
document.getElementById('commands').src="http://:1234@localhost:8080/requests/status.xml?command=in_enqueue&input="+url
}

</SCRIPT>
"@

$header="<html><head><title>" + $count +" Songs</title>"+"</head><body><table id=tblclass>"
$footer="<iframe src='' id='commands'></iframe></table></body></html>"

$count=$oArray | measure-object



$oArray | sort-object -property SongName | foreach {

	$HTML=$HTML+"<TR class=trclass><TD class=tdclass><A HREF=# onload='loadurl("+[System.Web.HttpUtility]::UrlEncode($_.SongURL)+");'>[Queue]</A></TD><TD>"+$_.SongName+"</TD></TR>"

}

$header+$HTML+$footer | out-file menu.html




