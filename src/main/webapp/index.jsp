<%@page import="jakarta.json.JsonObjectBuilder"%>
<%@page import="jakarta.json.Json"%>
<%@page import="jakarta.json.JsonArrayBuilder"%>
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
Copyright (C) 2015 DBC A/S (http://dbc.dk/)

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
        <style type="text/css">
            TEXTAREA {
                width: 100%;
                height: 50ex;
            }
        </style>
        <script type="text/javascript" src="jquery-1.11.1.min.js">
        </script>
        <script type="text/javascript" src="jquery-base64.min.js">
        </script>
        <script type="text/javascript" src="jquery-format.min.js">
        </script>
        <script type="text/javascript">
            var content = <%= makeConfig(request)%>;

            var service = null;
            var request = null;
            var dataUri = false;

            function NOW() {
                return new Date().toISOString();
            }

            function showWsdl() {
                if (service !== -1) {
                    var uri = content[service]['name'] + "?wsdl";
                    window.open(uri, "_blank");
                }
            }

            function fetchHTML(id, url) {
                $.ajax({
                    url: url,
                    success: function (data, status, request) {
                        var array = data.match(/(<body[^>]*>)([\s\S]*)(<\/body)/m);
                        $('#' + id).append($.parseHTML(array));
                        $("[id^='" + id + "_']").show();
                    }
                });
            }

            function regexpCallBack(total, match) {
                try {
                    return eval(match);
                } catch(exception) {
                    return "EXCEPTION:" + exception;
                }
            }

            function fetchXML(url) {
                $.ajax({
                    url: url,
                    dataType: 'text',
                    success: function (data, status, request) {
                        $('#xml').val(data.replace(/%\{([^]*?)\}%/g, regexpCallBack));
                    }
                });
            }

            function soapCallback(data, status, req) {
                try {
                    $('iframe')[0].contentWindow.document.body.hasChildNodes();
                    var uri = "data:" + data.getResponseHeader("Content-Type") + ";base64," + $.base64('encode', data.responseText);
                    window.open(uri, "_blank");
                } catch (e) {
                    if (typeof (data) === 'string') {
                        if (req.getResponseHeader("Content-Type").match(/^text\/xml/)) {
                            var content = $("<div>").val(data).format({method: 'xml'}).val();
                            var w = window.open();
                            var d = w.document;
                            var pre = d.createElement("pre");
                            pre.appendChild(d.createTextNode(content));
                            d.body.appendChild(pre);
                            d.close();
                        } else {
                            var w = window.open();
                            var d = w.document;
                            d.open('text/html', 'replace');
                            d.write(data);
                            d.close();
                        }
                    } else {
                        if (data.getResponseHeader("Content-Type").match(/^text\/xml/)) {
                            var content = $("<div>").val(data.responseText).format({method: 'xml'}).val();
                            var w = window.open();
                            var d = w.document;
                            var pre = d.createElement("pre");
                            pre.appendChild(d.createTextNode(content));
                            d.body.appendChild(pre);
                            d.close();
                        } else {
                            var w = window.open();
                            var d = w.document;
                            d.open('text/html', 'replace');
                            d.write(data.responseText);
                            d.close();
                        }
                    }
                }
            }

            function fetchSoap() {
                if (service === -1)
                    return;
                $.ajax({
                    type: 'POST',
                    url: content[service]['name'],
                    contentType: 'text/xml',
                    dataType: 'text',
                    data: $('#xml').val(),
                    success: soapCallback,
                    error: soapCallback
                });
            }

            function setupService(no) {
                if (service === no)
                    return;

                service = no;
                $('#service').hide();
                $('#header').contents().remove();
                $("[id^='header_']").hide();
                $('#footer').contents().remove();
                $("[id^='footer_']").hide();
                $('#xml').each(function () {
                    $(this).val('');
                });
                $('#requests').contents().each(function (no) {
                    if (no !== 0)
                        $(this).remove();
                });
                setupRequest(-1);

                if (no === -1)
                    return;

                $('#service').show();
                if (content[service]['header'] !== false) {
                    fetchHTML('header', content[service]['path'] + '/header.html');
                }
                if (content[service]['footer'] !== false) {
                    fetchHTML('footer', content[service]['path'] + '/footer.html');
                }

                $.each(content[service]['examples'], function (no) {
                    $('#requests').append($('<option>').append(document.createTextNode($(this)[0]['name'])));
                });
            }

            function setupRequest(no) {
                if (no === request)
                    return;

                request = no;
                $('#xml').val('');
                $('#doc').contents().remove();
                $("[id^='doc_']").hide();

                if (no === -1)
                    return;

                fetchXML(content[service]['path'] + '/' + content[service]['examples'][request]['path']);
                if (content[service]['examples'][request]['html'] !== false) {
                    fetchHTML('doc', content[service]['path'] + '/' + content[service]['examples'][request]['html']);
                }
            }

            $('document').ready(function (event) {
                $.each(content, function (no) {
                    $('#services').append($('<option>').append(document.createTextNode($(this)[0]['name'])));
                });
                if (content.length === 1) {
                    setupService(0);
                    $('#service_selector').hide();
                } else {
                    setupService(-1);
                }
            });
        </script>
    </head>
    <body>
        <h2>Copyright (C) 2015 DBC A/S (http://dbc.dk/)</h2>
        <p>SOAP Webservice test client</p>
        <div id="service_selector">
            <select id="services" onChange="setupService(this.selectedIndex - 1);"><option>Select service</option></select>
            <br>
            <hr>
        </div>
        <div id="service">
            <div id="header_1">
                <br>
            </div>
            <div id="header"></div>
            <div id="header_2">
                <br>
                <hr>
            </div>
            <textarea id="xml"></textarea>
            <br>
            <br>
            <select id="requests" onChange="setupRequest(this.selectedIndex - 1);"><option>Pick a request</option></select>
            <input type="button" value="Send Request" onclick="fetchSoap();">
            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
            <input type="button" value="Service WSDL" onclick="showWsdl();">
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
        <iframe style="display: none;" src="data:text/html,<html><body><hr></body></html>"></iframe>
    </body>
</html>
