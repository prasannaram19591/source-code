#!/bin/bash
DATE=`date +%Y_%m_%d`
yr=`date | awk '{print $6}'`
PATH=$PATH:$HOME/bin:~/.local/bin:$PATH

export PATH

#### Script Starting ###############

#CSV_FN=/tmp/output.csv
#CSV_FN=/tmp/out2.csv
CSV_FN=/root/opsk_portal/portal_list.csv
#CSV_FN=/root/scripts/os_inventory.csv

echo "<html>
<head>
<meta http-equiv="refresh" content="3600"/>
<style>
div.container {
    width: 100%;
}

.button {
  background-color: #008CBA;border-radius: 20px;padding: 8px 20px; /* Green */
  border: none;
  color: white;
  padding: 4px 10px;
  text-align: center;
  text-decoration: none;
  display: inline-block;
  font-size: 15px;
  margin: 4px 2px;
  cursor: pointer;
}
.button1 {background-color: #008CBA;border-radius: 20px;padding: 4px 20px;} /* Green */


.navbar-brand {
    float: left;
    padding: 5px 20px 50px;
    font-size: 18px;
    line-height: 15px;
    height: 0px;
}
#imgtype {-webkit-user-select: none;
        background-position: 0px 0px, 10px 10px;
        background-size: 15px 15px;
        background-image:linear-gradient(45deg, #eee 0%, white 0%, white 100%, #eee 75%, #eee 100%);
        width:135px;
        height:70px;}

#headtext {
    color: #ff3300;
    background-color: #e6fff7;
        padding: 15px 15px;
        font-size:40px;
        font-style:bold;
        padding:5px
        font-family:Aharoni;
        }
footer {
    padding: 1em;
    color: #34495E;
    font-style:bold;
    background-color: #e6fff7;
    clear: left;
}
.tabh {
    border-collapse: collapse;
    background-color:#ffffcc;
    width: 100%;
}
.tab th, td {
    text-align: left;
    padding: 8px;
}
th {
    font-family: Cambria;
    background-color: #006600;
    -webkit-font-smoothing: antialiased;
    text-rendering: optimizeLegibility;
    color:#ffffff;
}
td {
    font-family: Cambria;
    text-rendering: optimizeLegibility;
    color:#cc3300;
}

</style>
</head>
<body>
<div class="container">

<header>
<table>
<tr><td style="width:300px" id="headtext">
<h1 id="logo" class="navbar-brand"><img id="imgtype" src="OpenStack-Logo.png" alt="logo"/></h1></td><td id="headtext" width="200%" style="padding-left:300px">EV OpenStack Cloud Inventory Portal</td></tr>

<form method="get" action="portal_list.csv">
   <p align="right">
   <button class="button button1">Download CSV !</button>
   </p>
</form>

</table>
</header>"
echo "<table width=200 class='tabh'>"
head -n 1 $CSV_FN | \
    sed -e 's/^/<tr class='tab'><th>/' -e 's/,/<\/th><th>/g' -e 's/$/<\/th><\/tr>/'
tail -n +2 $CSV_FN | \
    sed -e 's/^/<tr class='tab'><td>/' -e 's/,/<\/td><td>/g' -e 's/$/<\/td><\/tr>/'
echo "</table>
<footer>Copyright $yr &copy; company LTD</footer>
</div>
</body>
</html>"
