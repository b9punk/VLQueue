#This project is WIP

$XMLfile="/home/luisfeliz/Downloads/playlist.xml"                           
$Pass="1234"
$htmldir="/home/luisfeliz/Documents/html"
$title=""

#Download latest ML list
write-host "Downloading latest ML List ..."

#Process Media List
write-host "Reading and processing list ..."

$f = [System.Xml.XmltextReader]::Create($XMLfile)
$f.read() | out-null

$oArray=@()

$f.ReadToFollowing("node") | out-null

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
    write-host " -- Top level"
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
	write-host " -- SubFolders"
	write-host "    -- "+$xml.node.node[1].$level.name
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

$count=($oArray | measure-object).count
write-host "Processed $count item(s)"

# Create Static Pages
write-host "Create static pages... " -nonewline

$script=@"
<SCRIPT>

function loadurl( url) {
//document.getElementById('commands').src="http://:1234@localhost:8080/requests/status.xml?command=in_enqueue&input="+url
document.getElementById('commands').src="http://localhost:8080/requests/status.xml?command=in_enqueue&input="+url

}

</SCRIPT>
"@


$index="ABCDEFGHIJKLMNOPQRSTUVWYXZ"

$top="<FORM id=topmenu class=formclass>"
$top+="<Select id=topmenuselect class=selectclass onChange='javascript:location.href = this.value;'>"
$top+="<option value='' selected>Select First Letter</option><option value=0-menu.html>Numbers and Symbols</option>"
$top+=$($index.ToCharArray()|foreach {"<option value=$_-menu.html>$_</option>"})
$top+="</select></FORM>"

$header="<html><head><title>" + $count +" Songs</title>"+$script+"<link rel='stylesheet' href='styles.css'></head>"
$header+="<body>$top<br><table id=tblclass>"
$footer="</table></body><iframe src='' id='commands' style='width:0;height:0;border:0;border:none'></iframe></html>"


$HTML=""
$c=0
write-host "[" -nonewline
$oArray | sort-object -property SongName -Culture 'en-US'  | foreach {


	#Added extra Normalization to compensate for unicode characters
	#Based on answers from here
	#https://stackoverflow.com/questions/36007233/sort-object-not-sorting-correctly-due-to-encoding-issue

	$firstChar=$_[0].SongName.toUpper()[0].ToString().Normalize([Text.NormalizationForm]::FormKD)[0]     
	
	if ($lastChar -eq $null) {$lastChar="0"}
	if ($index -like "*$firstChar*") {
		#We have made it to the alphabet - we assume Zs will be the last items on the list.
		if ($firstChar -ne $lastChar) {
			#Time to write the file and reset
			write-host $lastChar -nonewline
			$header+$HTML+$footer | out-file "$htmldir/$lastChar-menu.html"
			$HTML=""
			$HTML=$HTML+"<TR class=trclass><TD class=tdclass><A HREF=# onClick=loadurl('"+[System.Web.HttpUtility]::UrlEncode($_.SongURL)+"');>[Queue]</A></TD><TD>"+$_.SongName+"</TD></TR>"
			$lastChar=$firstChar


		} else {
			#Simply continue
			$HTML=$HTML+"<TR class=trclass><TD class=tdclass><A HREF=# onClick=loadurl('"+[System.Web.HttpUtility]::UrlEncode($_.SongURL)+"');>[Queue]</A></TD><TD>"+$_.SongName+"</TD></TR>"
		
		}

	} else {
		#Looks like it is a non-alphabet character, group them together
		$HTML=$HTML+"<TR class=trclass><TD class=tdclass><A HREF=# onClick=loadurl('"+[System.Web.HttpUtility]::UrlEncode($_.SongURL)+"');>[Queue]</A></TD><TD>"+$_.SongName+"</TD></TR>"
		$lastChar="0"
		
	}

}
write-host "]"



















