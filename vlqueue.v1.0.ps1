#This project is WIP
#v0.3

#Installation Instructions

	#Download the VLCQueue Package, it should include:
	# vlqueue.ps1
	# vlqueue.html
	# styles.css

#Install PowerShell
	#https://github.com/PowerShell/PowerShell

#Setup VLC Web Interface and set pass variable below
	#https://www.howtogeek.com/117261/how-to-activate-vlcs-web-interface-control-vlc-from-a-browser-use-any-smartphone-as-a-remote/

#Locate and make a VLCQueue directory under the VLC web interface html folder
	#For Linux /usr/share/vlc/lua/http
		# cd /usr/share/vlc/lua/http
		# sudo mkdir VLQueue 
		# sudo chmod 777 VLQueue
	#For Windows      C:\Program Files\VideoLAN\VLC\lua\http 
	#For Apple OS X   /Applications/VLC.app/Contents/MacOS/share/lua/http

#backup and Replace index.html
	#sudo cp index.html index.html.original
	#sudo cp ~/Downloads/vlqueue.html index.html

#Update the variables below as needed
#Run the VLQueue script
	#cd /home/user/Documents/VLQueue
	#pwsh vlqueue.ps1
	#close and restart VLC
	#Access the web interface at http://localhost:8080

#optionally specify your own CSS on styles.css
	#create file VLQueue/styles.css

#optionally set this script to run on a regular basis
	#to be completed

$htmldir="/usr/share/vlc/lua/http/VLQueue"
$XMLfile="$htmldir/playlist.xml"                           
$Pass="1234"
$title="Jen's Music Library"

#Setup a friendly DNS name for easier access
$VLCWebURL="http://localhost:8080" 



#Download latest ML list
write-host "Downloading latest ML List ..."
invoke-expression "curl -s -u :$pass $VLCWebURL/requests/playlist.xml > $XMLfile"

#Process Media List
write-host "Loading Media Library List ..."

$f = [System.Xml.XmltextReader]::Create($XMLfile)
$f.read() | out-null

$oArray=@()

$f.ReadToFollowing("node") | out-null

[xml]$xml=$f.ReadOuterXml()
$StartNode="/node/node[2]"

write-host "Processing Media Library List ..."
    
	$xml.selectNodes("$StartNode//leaf") | foreach {

	if ($($_.'name' -notlike "*.cdg*")) {
	$oarray += new-object PSObject -property ([ordered]@{

	  #Select-XML allows you to address XML elements as they appear on the file
	  "SongName"    = $_.'name'
	  "SongURL"     = $_.'uri'
	  "SongID"   = $_.'id'

	}) #new-object
      }#if
   }#for
<#
    #and now Sub levels
    if ($xml.selectNodes("$startnode/$selector/node") -ne $null) {
		#Ok there are more nodes, so iterate
		$selector+="/node"
		ProcessMediaLibraryList -selector $selector
    }
	else {
		#no more nodes, leave
	}
	
#>


$count=($oArray | measure-object).count
write-host "Processed $count item(s)"

# Create Static Pages
write-host "Create static pages... " -nonewline

$script=@"
<SCRIPT>

function loadurl( url) {
//document.getElementById('commands').src="http://:1234@localhost:8080/requests/status.xml?command=in_enqueue&input="+url
document.getElementById('commands').src="/requests/status.xml?command=in_enqueue&input="+url

}

</SCRIPT>
"@


$index="ABCDEFGHIJKLMNOPQRSTUVWYXZ"



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

			$top="<FORM id=topmenu class=formclass>"
			$top+="<Select id=topmenuselect class=selectclass onChange='javascript:location.href = this.value;'>"
			$top+="<option value=''>Select First Letter</option><option value=0-menu.html>Numbers and Symbols</option>"
			$top+=$($index.ToCharArray()|foreach { if ($_ -eq $lastChar){"<option value=$_-menu.html selected>Songs that start with $_</option>"} else {"<option value=$_-menu.html>Songs that start with $_</option>" }})
			$top+="</select></FORM>"
			
			$header="<html><head><title>"+ $title + " Songs</title>"+$script+"<link rel='stylesheet' href='styles.css'></head>"
			$header+="<body><p class=titleclass>$title - $count song(s)</p><br>$top<br><table id=tblclass>"
			$footer="</table></body><iframe src='$VLCWebURL' id='commands' style='width:0;height:0;border:0;border:none'></iframe></html>"
	

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
write-host "Done :-)"


#to be fixed:
#html files for the are no songs for a specific alphabet letter

















