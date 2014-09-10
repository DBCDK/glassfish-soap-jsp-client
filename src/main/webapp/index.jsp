<%@page import="javax.json.JsonObjectBuilder"%>
<%@page import="javax.json.Json"%>
<%@page import="javax.json.JsonArrayBuilder"%>
<%@page import="java.util.regex.Matcher"%>
<%@page import="java.util.regex.Pattern"%>
<%@page import="java.util.Comparator"%>
<%@page import="java.util.Arrays"%>
<%@page import="java.io.FileFilter"%>
<%@page import="java.io.File"%>
<%!
    public static File[] listEntries(File path, final String extension) {
        File[] files = path.listFiles(new FileFilter() {
            @Override
            public boolean accept(File pathname) {
                return pathname.getName().endsWith(extension);
            }
        });
        Arrays.sort(files, new Comparator<File>() {
            @Override
            public int compare(File o1, File o2) {
                return normalize(o1.getName()).compareTo(normalize(o2.getName()));
            }
        });
        return files;
    }

    private static final Pattern normalizePattern = Pattern.compile("(\\D*)0*(\\d+)");

    private static String normalize(String in) {
        Matcher matcher = normalizePattern.matcher(in);
        StringBuilder sb = new StringBuilder();
        int end = 0;
        while (matcher.find()) {
            end = matcher.end();
            sb.append(matcher.group(1)).append("0").append('@' + matcher.group(2).length()).append(matcher.group(2));
        }
        sb.append(in.substring(end));
        return sb.toString();
    }

    public static String makeConfig(HttpServletRequest request) {
        ServletContext context = request.getServletContext();
        File path = new File(context.getRealPath(request.getServletPath())).getParentFile();

        JsonArrayBuilder jsonDirs = Json.createArrayBuilder();
        for (File dir : listEntries(path, ".examples")) {
            JsonObjectBuilder jsonDir = Json.createObjectBuilder();
            String dirName = dir.getName();
            jsonDir.add("path", dirName);
            jsonDir.add("name", dirName.substring(0, dirName.length() - ".examples".length()));
            jsonDir.add("header", dir.toPath().resolve("header.html").toFile().exists());
            jsonDir.add("footer", dir.toPath().resolve("footer.html").toFile().exists());
            JsonArrayBuilder jsonExamples = Json.createArrayBuilder();
            for (File file : listEntries(dir, ".xml")) {
                JsonObjectBuilder jsonExample = Json.createObjectBuilder();
                String examplePath = file.getName();
                jsonExample.add("path", examplePath);
                String exampleName = examplePath.substring(0, examplePath.length() - ".xml".length());
                jsonExample.add("name", exampleName);
                File htmlFile = file.toPath().resolveSibling(exampleName + ".html").toFile();
                if (htmlFile.exists()) {
                    jsonExample.add("html", htmlFile.getName());
                } else {
                    jsonExample.add("html", false);

                }
                jsonExamples.add(jsonExample);
            }
            jsonDir.add("examples", jsonExamples);

            jsonDirs.add(jsonDir);
        }
        return jsonDirs.build().toString();
    }

%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<!--
Copyright (C) 2014 DBC A/S (http://dbc.dk/)

This is part of glassfish-soap-jsp-client

glassfish-soap-jsp-client is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

glassfish-soap-jsp-client is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
-->
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>Soap webservice test client</title>
        <script type="text/javascript">
            var content = <%= makeConfig(request)%>;
            var endpoint = null;
            var request = null;
            var Base64 = {// http://stackoverflow.com/questions/246801/how-can-you-encode-a-string-to-base64-in-javascript
                _keyStr: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",
                encode: function(input) {
                    var output = "";
                    var chr1, chr2, chr3, enc1, enc2, enc3, enc4;
                    var i = 0;
                    input = Base64._utf8_encode(input);
                    while (i < input.length) {
                        chr1 = input.charCodeAt(i++);
                        chr2 = input.charCodeAt(i++);
                        chr3 = input.charCodeAt(i++);
                        enc1 = chr1 >> 2;
                        enc2 = ((chr1 & 3) << 4) | (chr2 >> 4);
                        enc3 = ((chr2 & 15) << 2) | (chr3 >> 6);
                        enc4 = chr3 & 63;
                        if (isNaN(chr2)) {
                            enc3 = enc4 = 64;
                        } else if (isNaN(chr3)) {
                            enc4 = 64;
                        }
                        output = output +
                                Base64._keyStr.charAt(enc1) + Base64._keyStr.charAt(enc2) +
                                Base64._keyStr.charAt(enc3) + Base64._keyStr.charAt(enc4);
                    }
                    return output;
                },
                _utf8_encode: function(string) {
                    var utftext = "";
                    for (var n = 0; n < string.length; n++) {
                        var c = string.charCodeAt(n);
                        if (c < 128) {
                            utftext += String.fromCharCode(c);
                        } else if ((c > 127) && (c < 2048)) {
                            utftext += String.fromCharCode((c >> 6) | 192);
                            utftext += String.fromCharCode((c & 63) | 128);
                        } else {
                            utftext += String.fromCharCode((c >> 12) | 224);
                            utftext += String.fromCharCode(((c >> 6) & 63) | 128);
                            utftext += String.fromCharCode((c & 63) | 128);
                        }
                    }
                    return utftext;
                }
            }

            function xmlHttp() {

                var xmlhttp = false;
                /*@cc_on @*/
                /*@if (@_jscript_version >= 5)
                 // JScript gives us Conditional compilation, we can cope with old IE versions.
                 // and security blocked creation of the objects.
                 try {
                 xmlhttp = new ActiveXObject("Msxml2.XMLHTTP");
                 } catch (e) {
                 try {
                 xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
                 } catch (E) {
                 xmlhttp = false;
                 }
                 }
                 @end @*/
                if (!xmlhttp && typeof XMLHttpRequest !== 'undefined') {
                    try {
                        xmlhttp = new XMLHttpRequest();
                    } catch (e) {
                    }
                }
                if (!xmlhttp && window.createRequest) {
                    try {
                        xmlhttp = window.createRequest();
                    } catch (e) {
                    }
                }
                if (!xmlhttp && window.XMLHttpRequest) {
                    try {
                        xmlhttp = new window.XMLHttpRequest();
                    } catch (e) {
                    }
                }
                if (!xmlhttp) {
                    try {
                        xmlhttp = new ActiveXObject("MSXML2.XMLHTTP.3.0");
                    } catch (ex) {
                    }
                }
                return xmlhttp;
            }

            function sendSoap(url, content) {
                var xmlhttp = xmlHttp();
                xmlhttp.open("POST", url, true);
                xmlhttp.setRequestHeader("Content-Type", "text/xml");
                xmlhttp.onreadystatechange = function() {
                    if (xmlhttp.readyState === 4) {
                        var uri = "data:text/xml;base64," + Base64.encode(xmlhttp.responseText);
                        window.open(uri, "_blank");
                    }
                };
                xmlhttp.send(content);
            }

            function requestXml(url, id) {
                var element = document.getElementById(id);
                var xmlhttp = xmlHttp();
                xmlhttp.open("GET", url, true);
                xmlhttp.onreadystatechange = function() {
                    if (xmlhttp.readyState === 4 && xmlhttp.status === 200 && xmlhttp.responseXML !== null) {
                        element.value = xmlhttp.responseText;
                    }
                };
                xmlhttp.send();
            }

            function requestHtml(url, id) {
                var element = document.getElementById(id);
                var xmlhttp = xmlHttp();
                xmlhttp.open("GET", url, true);
                xmlhttp.responseType = "document";
                xmlhttp.onreadystatechange = function() {
                    if (xmlhttp.readyState === 4 && xmlhttp.status === 200 && xmlhttp.responseXML !== null) {
                        var body = xmlhttp.responseXML.body;
                        if (body.hasChildNodes()) {
                            var e;
                            var i = 1;
                            for (; ; ) {
                                e = document.getElementById(id + '_' + i++);
                                if (e === null)
                                    break;
                                e.style.display = 'initial';
                            }
                        }
                        while (body.hasChildNodes()) {
                            var e = document.adoptNode(body.firstChild, true);
                            element.appendChild(e);
                        }
                    }
                };
                xmlhttp.send();
            }

            function clearElement(id) {
                var e = document.getElementById(id);
                while (e.hasChildNodes()) {
                    e.removeChild(e.firstChild);
                }
                var i = 1;
                for (; ; ) {
                    e = document.getElementById(id + '_' + i++);
                    if (e === null)
                        break;
                    e.style.display = 'none';
                }
            }

            function setupEndpoints() {
                document.getElementById('xml').value = '';
                clearElement('endpoints');
                clearElement('picker');
                clearElement('header');
                clearElement('doc');
                clearElement('footer');
                document.getElementById("endpoint_wrapper").style.display = 'none';
                if (content.length === 1) {
                    document.getElementById("endpoints_wrapper").style.display = 'none';
                    setupEndpoint(0);
                    return;
                }
                var select = document.getElementById("endpoints");
                var option = document.createElement('option');
                option.appendChild(document.createTextNode("Pick a service"));
                select.appendChild(option);
                content.forEach(function(v) {
                    var option = document.createElement('option');
                    option.appendChild(document.createTextNode(v['name']));
                    select.appendChild(option);
                });
            }

            function setupEndpoint(n) {
                document.getElementById('xml').value = '';
                var select = document.getElementById("picker");
                clearElement('picker');
                clearElement('header');
                clearElement('doc');
                clearElement('footer');
                if (n === -1) {
                    document.getElementById("endpoint_wrapper").style.display = 'none';
                    endpoint = request = null;
                    return;
                }
                document.getElementById("endpoint_wrapper").style.display = 'inherit';
                endpoint = content[n];
                var option = document.createElement('option');
                option.appendChild(document.createTextNode("Pick a request"));
                select.appendChild(option);
                endpoint['examples'].forEach(function(v) {
                    var option = document.createElement('option');
                    option.appendChild(document.createTextNode(v['name']));
                    select.appendChild(option);
                });

                if (endpoint['header']) {
                    requestHtml(endpoint['path'] + "/header.html", 'header');
                }
                if (endpoint['footer']) {
                    requestHtml(endpoint['path'] + "/footer.html", 'footer');
                }
            }

            function setupRequest(n) {
                document.getElementById('xml').value = '';
                clearElement('doc');
                if (n === -1) {
                    request = null;
                    return;
                }
                request = endpoint['examples'][n];
                requestXml(endpoint['path'] + '/' + request['path'], 'xml');
                if (request['html']) {
                    requestHtml(endpoint['path'] + '/' + request['html'], 'doc');
                }
            }

            function sendRequest() {
                sendSoap(endpoint['name'], document.getElementById('xml').value);
            }

            function showWsdl() {
                if (endpoint !== null) {
                    var uri = endpoint['name'] + "?wsdl";
                    window.open(uri, "_blank");
                }
            }
        </script>
    </head>
    <body onload="setupEndpoints()">
        <h2>Copyright (C) 2014 DBC A/S (http://dbc.dk/)</h2>
        <div id="endpoints_wrapper">
            <select id="endpoints" onChange="setupEndpoint(this.selectedIndex - 1);"></select>
            <br>
            <hr>
        </div>
        <div id="endpoint_wrapper">
            <div id="header_1">
                <br>
            </div>
            <div id="header"></div>
            <div id="header_2">
                <br>
                <hr>
            </div>
            <input type="button" value="Service WSDL" onclick="showWsdl();">
            <br>
            <textarea id="xml" rows=20 cols=90></textarea>
            <br>
            <br>
            <select id="picker" onChange="setupRequest(this.selectedIndex - 1);"></select>
            <input type="button" value="Try me" onclick="sendRequest();">
            <br>
            <br>
        </div>
        <div id="doc_1">
            <br>
            <hr>
            <br>
        </div>
        <div id="doc"></div>
        <div id="footer_1">
            <br>
            <hr>
            <br>
        </div>
        <div id="footer"></div>
    </body>
</html>
