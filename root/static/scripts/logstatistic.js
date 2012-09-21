/*
    Copyright (C) 2012 Daniel Bali

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA. 
*/

$(function () {
    var page_title = '/log-statistics';
    var divs = $(".data");
    
    // Datepicker functions
    var category = $(divs[0]).attr("data-statistic-category");
    $("#datepicker").datepicker({
        dateFormat: "yy-mm-dd",
        minDate: new Date($("#datepicker").attr("data-min-date")),
        maxDate: new Date($("#datepicker").attr("data-max-date"))
    });
    $("#datebutton").click(function () {
        window.location = page_title + '/' + encodeURIComponent(category).toLowerCase()
            + '/' + $("#datepicker").datepicker({dateFormat: 'yy-mm-dd'}).val();
    });
    $("#date_changer").children().click(function () { 
        $("#date_selector").show("slow"); 
    });
    
    
    for (var i = 0; i < divs.length; ++i) {
        var category = $(divs[i]).attr("data-statistic-category");
        var name = $(divs[i]).attr("data-statistic-name");
        var timestamp = $(divs[i]).attr("data-statistic-timestamp");
        
        // Fetch data with ajax
        $.ajax({
            url: page_title + '/json/' + encodeURIComponent(category) + '/' + encodeURIComponent(name) + '/' + timestamp,
            dataType: 'json',
            aCategory: category,
            aName: name,
            aTimestamp: timestamp,
            success: function(json) {
                populateTable(this.aCategory, this.aName, this.aTimestamp, json);
                createGraph(this.aCategory, this.aName, this.aTimestamp, json);
            }
        });
    }
    
    // Populates tables with data from json
    function populateTable(category, name, timestamp, json) {
        
        var table = $('div[class="data"]'
            + '[data-statistic-category="'+category+'"]'
            + '[data-statistic-name="'+name+'"]'
            + '[data-statistic-timestamp="'+timestamp+'"]').children("table")[0];
        
        // Create innerHTML for table
        var tableData = '<thead><tr><th>#</th>';
        for (var key in json.data[0]) {
            if (json.data[0].hasOwnProperty(key)) {
                tableData = tableData.concat('<th>' + key + '</th>');
            }
        }
        tableData = tableData.concat('</tr></thead><tbody>');
        for (var i = 0; i<json.data.length; ++i) {
            tableData = tableData.concat('<tr ');
            if (i % 2 != 0) {
                tableData = tableData.concat('class="ev"');
            }
            tableData = tableData.concat('><td>' + (i+1) + '</td>');
            for (var key in json.data[i]) {
                if (json.data[0].hasOwnProperty(key)) {
                    tableData = tableData.concat('<td>' + json.data[i][key] + '</td>');
                }
            }
            tableData = tableData.concat('</tr>');
        }
        tableData = tableData.concat('</tbody>');
        
        // Set innerHTML
        table.innerHTML = tableData;
        
        // Hide rows over the limit given
        hideRows(table, json.display.limit);
        
        // Handle "show more" label
        var more_data = $('p[class="more-data"]'
            + '[data-statistic-category="'+category+'"]'
            + '[data-statistic-name="'+name+'"]'
            + '[data-statistic-timestamp="'+timestamp+'"]');
            
        if (table.tBodies[0].rows.length <= json.display.limit) {
            more_data.hide();
        } else {
            more_data.click(function() {
                if ($(this).children().text() == "(show more)") {
                    $(table.tBodies[0].rows).show();
                    $(this).children().text("(show less)");
                } else {
                    hideRows(table, json.display.limit, 0);
                    $(this).children().text("(show more)");
                }
            });
        }
    }
    
    // Displays graphs, handles tables that contain data
    function createGraph(category, name, timestamp, json) {
    
        var graph = $('div[class="graph"]'
            + '[data-statistic-category="'+category+'"]'
            + '[data-statistic-name="'+name+'"]'
            + '[data-statistic-timestamp="'+timestamp+'"]');
        var data;
        var options;
        
        // If no graph is needed, hide the div
        // Make the table full-width
        if (!json.display.mapping) {
            graph.hide();
            $('div[class="data"]'
                + '[data-statistic-category="'+category+'"]'
                + '[data-statistic-name="'+name+'"]'
                + '[data-statistic-timestamp="'+timestamp+'"]')[0].style.width = "90%";
            return;
        }
        
        // Handle pie charts differently
        if (json.display.mapping.type == "pie") {
            var i = 0;
            data = $.map(json.data, function(e) { 
                return { 
                    label: e[json.display.mapping.xaxis], 
                    data: parseInt(e[json.display.mapping.yaxis]) 
                };
            });
            
            options = {
                series: {
                    pie: {
                        innerRadius: 0.5,
                        show: true
                    }
                }
            };
        } else {
            // Create ticks
            var i = 0;
            var x_ticks;
            if (json.display.mapping.xaxis == '#') {
                x_ticks = $.map(json.data, function(e) { return [[i++, '#' + i]]});
            } else {
                x_ticks = $.map(json.data, function(e) {
                    return [[i++, 
                        e[json.display.mapping.xaxis].length > 12 ? 
                            e[json.display.mapping.xaxis].slice(0, 10).concat('..') : 
                            e[json.display.mapping.xaxis]]] 
                });
            }
            
            i = 0;
            var points = $.map(json.data.splice(0, json.display.limit), function(e) { 
                return [[i++, e[json.display.mapping.yaxis]]] 
            });
            data = [
                {
                    data: points,
                    color: '#BADA55',
                }
            ];
            
            // Add display type to data
            data[0][json.display.mapping.type] = {show: true, align: 'center'};
            
            options = {
                xaxis: { 
                    ticks: x_ticks, 
                    font: { size: 14 }
                }
            };
            
        }

        $.plot(graph, data, options);
        graph.resize(function () {});
    }

    function hideRows(table, limit, speed) {
        $($(table.tBodies[0].rows).splice(limit)).hide();
    }
});