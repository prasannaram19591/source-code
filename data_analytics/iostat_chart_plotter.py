import pandas as pd
import sys
import re
import os
import os.path

#Opening destination excel file using xlsxwriter..
writer = pd.ExcelWriter('iostat-stats-charts.xlsx', engine='xlsxwriter')

#Setting runtime variables for charts..
cnt = 0
chart_cell_cnt = 10
Chart_Bottom_Value = 'Timestamp'
Chart_Type = 'line'
Chart_Sub_Type = 'stacked'
Chart_Value_Font_Type = 'consolas'
Chart_Series_1_colour = 'blue'
Chart_Series_2_colour = 'red'
Chart_Area_Colour = '#DCFAFC'
Plot_Area_Colour = '#DCFAFC'
Cell_Colour = '#EA9432'
Legend_Display_Colour = '#EF1A71'
Legend_Header_Colour = '#1A88EF'
Chart_Series_1_Value_Position = 'above'
Chart_Series_2_Value_Position = 'below'

#setting axis length..
x_scale = 0.9
y_scale = 1.1

#Creating Summary and Chart sheets on the destination file..
sh1 = pd.DataFrame ()
sh1.to_excel(writer, sheet_name='Summary', index=False)
sheet_name = 'Summary'
sh1.to_excel(writer, sheet_name=sheet_name)
workbook = writer.book
worksheet = writer.sheets[sheet_name]
bold = workbook.add_format({'bold': True})
cell_format = workbook.add_format()
cell_format.set_font_color(Cell_Colour)
cell_format.set_font_size(16)
cell_format.set_bold()
worksheet.write('L1', 'IOstat Charts', cell_format)
worksheet.write('J3', 'Read Write comparision for all the logical block device', bold)

#Computing the number of entries to plot..
with open('files.txt', 'r') as f:
     for line in f:
        cnt += 1
        msg = str('Charting the file ' + line.rstrip('\n'))
        print (msg)
        with open(line.rstrip('\n'), 'r') as file:
            lines = 0
            Content = file.read()
            CoList = Content.split("\n")
            for i in CoList:
                if i:
                    lines += 1
        lines -= 1
        
        #Creating sheet in destination excel file..
        legend = line.split(".")[0]
        size = legend.split("_")[0]
        title = legend.lower()
        data = pd.read_csv(line.rstrip('\n'))
        sheet_name = "sheet" + str(cnt)
        data.to_excel(writer, sheet_name=sheet_name)
        workbook = writer.book
        worksheet = writer.sheets[sheet_name]

        #Setting font size and colour..
        bold = workbook.add_format({'bold': True})
        
        cell_format = workbook.add_format()
        cell_format.set_font_color(Cell_Colour)
        cell_format.set_font_size(16)
        cell_format.set_bold()
        
        legend_value_format = workbook.add_format()
        legend_value_format.set_font_color(Legend_Display_Colour)
        legend_value_format.set_bold()

        legend_header_format = workbook.add_format()
        legend_header_format.set_font_color(Legend_Header_Colour)
        legend_header_format.set_bold()


        #Addding chart for Read and Write IOPS..
        Title_Name = 'IOPS plot - ' + title
        Series_1_Name = 'Read IOPS'
        Series_2_Name = 'Write IOPS'

        chart = workbook.add_chart({'type': Chart_Type})
        
        #Including y axis values to chart..
        chart.add_series({
            'name': Series_1_Name,
            'categories': [sheet_name, 1, 1, lines, 1],
            'values':     [sheet_name, 1, 2, lines, 2],
            #'data_labels': {
            #    'value': True,
            #    'position': Chart_Series_1_Value_Position,
            #    'font': {'name': Chart_Value_Font_Type, 'color': Chart_Series_1_colour}
            #    },
        })

        #Including y2 axis values to chart..
        chart.add_series({
            'name': Series_2_Name,
            'categories': [sheet_name, 1, 1, lines, 1],
            'values':     [sheet_name, 1, 3, lines, 3],
            'y2_axis': True,
            #'data_labels': {
            #    'value': True,
            #    'position': Chart_Series_2_Value_Position,
            #    'font': {'name': Chart_Value_Font_Type, 'color': Chart_Series_2_colour}
            #    },
        })
        
        #Setting attributes for background chart area..
        chart.set_chartarea({
            'border': {'none': True},
            'fill':   {'color': Chart_Area_Colour}
        })

        #Setting attributes for actual plot area..
        chart.set_plotarea({
            'border': {'none': True},
            'fill':   {'color': Plot_Area_Colour}
        })

        #Creating a milti axis chart and setting attributes..
        chart.set_x_axis({'name': Chart_Bottom_Value, 'position_axis': 'on_tick'})
        chart.set_y_axis({'name': Series_1_Name, 'major_gridlines': {'visible': False}})
        chart.set_y2_axis({'name': Series_2_Name})
        chart.set_legend({'position': 'top'})
        chart.set_title({'name': Title_Name})
        chart.set_size({'x_scale': x_scale, 'y_scale': y_scale})
        chart.set_style(2)

        sheet_name = 'Summary'
        worksheet = writer.sheets[sheet_name]
        worksheet.insert_chart('A' + str(chart_cell_cnt), chart)
        
        #Addding chart for Read and Write Bandwidth..
        sheet_name = "sheet" + str(cnt)
        worksheet = writer.sheets[sheet_name]
       
        Title_Name = 'Bandwidth plot - ' + title
        Series_1_Name = 'Read BW'
        Series_2_Name = 'Write BW'

        chart = workbook.add_chart({'type': Chart_Type})

        #Including y axis values to chart..
        chart.add_series({
            'name': Series_1_Name,
            'categories': [sheet_name, 1, 1, lines, 1],
            'values':     [sheet_name, 1, 4, lines, 4],
            #'data_labels': {
            #    'value': True,
            #    'position': Chart_Series_1_Value_Position,
            #    'font': {'name': Chart_Value_Font_Type, 'color': Chart_Series_1_colour}
            #    },
        })

        #Including y2 axis values to chart..
        chart.add_series({
            'name': Series_2_Name,
            'categories': [sheet_name, 1, 1, lines, 1],
            'values':     [sheet_name, 1, 5, lines, 5],
            'y2_axis': True,
            #'data_labels': {
            #    'value': True,
            #   'position': Chart_Series_2_Value_Position,
            #    'font': {'name': Chart_Value_Font_Type, 'color': Chart_Series_2_colour}
            #    },
        })

        #Setting attributes for background chart area..
        chart.set_chartarea({
            'border': {'none': True},
            'fill':   {'color': Chart_Area_Colour}
        })

        #Setting attributes for actual plot area..
        chart.set_plotarea({
            'border': {'none': True},
            'fill':   {'color': Plot_Area_Colour}
        })

        #Creating a milti axis chart and setting attributes..
        chart.set_x_axis({'name': Chart_Bottom_Value, 'position_axis': 'on_tick'})
        chart.set_y_axis({'name': Series_1_Name, 'major_gridlines': {'visible': False}})
        chart.set_y2_axis({'name': Series_2_Name})
        chart.set_legend({'position': 'top'})
        chart.set_title({'name': Title_Name})
        chart.set_size({'x_scale': x_scale, 'y_scale': y_scale})
        chart.set_style(2)
        
        sheet_name = 'Summary'
        worksheet = writer.sheets[sheet_name]
        worksheet.insert_chart('H' + str(chart_cell_cnt), chart)

        #Addding chart for Read and Write Average Latency..
        sheet_name = "sheet" + str(cnt)
        worksheet = writer.sheets[sheet_name]

        Title_Name = 'Latency plot - ' + title
        Series_1_Name = 'Read Latency'
        Series_2_Name = 'Write Latency'

        chart = workbook.add_chart({'type': Chart_Type})

        #Including y axis values to chart..
        chart.add_series({
            'name': Series_1_Name,
            'categories': [sheet_name, 1, 1, lines, 1],
            'values':     [sheet_name, 1, 10, lines, 10],
            #'data_labels': {
            #    'value': True,
            #    'position': Chart_Series_1_Value_Position,
            #    'font': {'name': Chart_Value_Font_Type, 'color': Chart_Series_1_colour}
            #    },
        })

        #Including y2 axis values to chart..
        chart.add_series({
            'name': Series_2_Name,
            'categories': [sheet_name, 1, 1, lines, 1],
            'values':     [sheet_name, 1, 11, lines, 11],
            'y2_axis': True,
            #'data_labels': {
            #    'value': True,
            #    'position': Chart_Series_2_Value_Position,
            #    'font': {'name': Chart_Value_Font_Type, 'color': Chart_Series_2_colour}
            #    },
        })

        #Setting attributes for background chart area..
        chart.set_chartarea({
            'border': {'none': True},
            'fill':   {'color': Chart_Area_Colour}
        })

        #Setting attributes for actual plot area..
        chart.set_plotarea({
            'border': {'none': True},
            'fill':   {'color': Plot_Area_Colour}
        })

        #Creating a milti axis chart and setting attributes..
        chart.set_x_axis({'name': Chart_Bottom_Value, 'position_axis': 'on_tick'})
        chart.set_y_axis({'name': Series_1_Name, 'major_gridlines': {'visible': False}})
        chart.set_y2_axis({'name': Series_2_Name})
        chart.set_legend({'position': 'top'})
        chart.set_title({'name': Title_Name})
        chart.set_size({'x_scale': x_scale, 'y_scale': y_scale})
        chart.set_style(2)
       
        sheet_name = 'Summary'
        worksheet = writer.sheets[sheet_name]
        worksheet.insert_chart('O' + str(chart_cell_cnt), chart)

        chart_cell_cnt += 16

#Saving the destination spreadsheet..
writer.close()

