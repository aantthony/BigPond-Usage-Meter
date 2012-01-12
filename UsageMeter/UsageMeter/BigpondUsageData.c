/*
 
 BigpondUsageData.c
 UsageMeter
 
 Created by Anthony Foster on 21/09/11.
 
 Copyright (c) 2011 Anthony Foster.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 */

#include "BigpondUsageData.h"

#include <libxml/tree.h>
#include <libxml/parser.h>
#include <libxml/HTMLparser.h>
#include <libxml/xpath.h>
#include <libxml/xpathInternals.h>

#include <string.h>

typedef struct{
    xmlXPathContextPtr context;
    xmlXPathObjectPtr object;
    xmlNodePtr * nodes;
    int count;
} xPathQuery;

xPathQuery query(xmlNodePtr doc, const char * query_s, int *err);
void doneQuery(xPathQuery q);
int parseDateNode(xmlNodePtr node, int *err);

#pragma mark -
#pragma mark XPathQuery

xPathQuery query(xmlNodePtr doc, const char * query_s, int *err) {
    xPathQuery q;
    if((q.context = xmlXPathNewContext((xmlDocPtr)doc)) == NULL) {
        *err = UMError_CouldNotCreateXPathContext;
        return q;
    }
    if((q.object = xmlXPathEvalExpression((xmlChar *)query_s, q.context)) == NULL) {
        *err=UMError_CouldNotEvaluateExpression;
        return q;
    }
    if(!(q.object->nodesetval)) {
        //*err=UMError_NullNodeSet;
        q.count = 0;
    }else{
        q.nodes = q.object->nodesetval->nodeTab;
        q.count = q.object->nodesetval->nodeNr;
        
        if(q.count==0){
            xmlXPathFreeObject(q.object);
            xmlXPathFreeContext(q.context);
        }
    }
    return q;
}
void doneQuery(xPathQuery q) {
    if(q.count == 0){
        return;
    }
    xmlXPathFreeObject(q.object);
    xmlXPathFreeContext(q.context);
    q.count = 0;
}

#pragma mark -
#pragma mark Parsers
int parseDateNode(xmlNodePtr node, int *err) {
    unsigned char * date = (unsigned char *)node->children[0].content;
    int day=0;
    if(date[2] == ' ') {
        day = 10*(date[0] - '0') + date[1] - '0';
    }else if(date[1]==' ') {
        day = date[1]-'0';
    }else{
        *err = UMError_DateParseError;
    }
    return day;
}
int str_str_l(const char * haystack, const char * needle, int haystack_size);
int str_str_l(const char * haystack, const char * needle, int haystack_size){
    int start = 0;
    int len=0;
    int a;
    while(1){
        while(1){
            if(start+len>=haystack_size){
                return -1;
            }
            a = haystack[start+len];
            if(!needle[len]){
                return start;
            }else if(a == needle[len]){
                len++;
            }else{
                len=0;
                break;
            }
        }
        start++;
    }
}
#pragma mark -
#pragma mark Exposed Methods
enum UMError UMUsageDataFromHTML  (const char *buffer,int buffer_size, UMUsageData* result) {
    
    UMDailyUsageData *daily = result->daily;
    
	xmlDocPtr doc = htmlReadMemory(buffer, buffer_size, "", NULL, HTML_PARSE_NOWARNING | HTML_PARSE_NOERROR);
	
    if (doc == NULL) {
		return UMError_CouldNotLoadHTML;
    }
    int err = UMError_OK;
    
    int dayIndex;
    for(dayIndex = 0; dayIndex < UM_MAX_DAYS; dayIndex++) {
        daily[dayIndex].date = 0;
    }
    
    //Find the main daily usage table:
    xPathQuery q = query((xmlNodePtr)doc, "//table[@cellpadding = '3' and not(@class='usageScale')]", &err);
    if(q.count == 1) {
        dayIndex = 0;
        xmlNodePtr dailyUsageTable = q.nodes[0];
        xPathQuery rows = query(dailyUsageTable, "//tr[position()>1]", &err);
        int row_id;
        
        //For every row in the table:
        for(row_id = 0; row_id < rows.count - 1; row_id++) {
            
            //Find the date:
            xPathQuery dateQuery = query(rows.nodes[row_id], "/td[@nowrap]", &err);
            if(dateQuery.count>=1) {
                if(dayIndex < UM_MAX_DAYS) {
                    daily[dayIndex].date = parseDateNode(dateQuery.nodes[0], &err);
                }
            } else {
                err = UMError_DateFieldMissing;
            }
            doneQuery(dateQuery);
            
            //Find the fields, download MB, upload MB, etc.
            xPathQuery fields = query(rows.nodes[row_id], "/td[@align = 'right']", &err);
            int field_index;
            if(fields.count+1 != UM_NUM_FIELDS) {
                err = UMError_FieldsMissing;
            }
            for(field_index=0;field_index<fields.count && (field_index+1) < UM_NUM_FIELDS;field_index++) {
                //it's +1 because field_index does not include the date field
                xmlNodePtr field = fields.nodes[field_index];
                if(dayIndex < UM_MAX_DAYS) {
                    daily[dayIndex].value[field_index+1] = atoi((char*) field->children[0].content);
                }
            }
            doneQuery(fields);
            
            dayIndex++;
        }
        
        //The last row will be the totals... I think.
        xPathQuery total_row_fields = query(rows.nodes[row_id], "/td[@align='right']/strong", &err);
        if(total_row_fields.count + 1 != UM_NUM_FIELDS) {
            err = UMError_TotalsFieldsMissing;
        }
        daily[dayIndex].date = -1; // These are the totals. The -1 signals that fact.
        int field_index;
        for(field_index=0;field_index<total_row_fields.count && (field_index+1) < UM_NUM_FIELDS;field_index++) {
            //it's +1 because field_index does not include the date field
            xmlNodePtr field = total_row_fields.nodes[field_index];
            if(dayIndex < UM_MAX_DAYS) {
                daily[dayIndex].value[field_index+1] = atoi((char *) field->children[0].content);
            }
        }
        //Number of days (not including the totals entry, which can be accessed by result->daily[result->count])
        result->count = dayIndex;
        doneQuery(total_row_fields);
        
        doneQuery(rows);
        
        //Try to fid the plan size:
        
        result->plan = 0;
        xPathQuery label_values = query((xmlNodePtr)doc, "//table[@class = 'label-value']//tr", &err);
        int label_index;
        int found_all_labels = 0;
        for(label_index=0; !found_all_labels && (label_index<label_values.count);label_index++) {
            xmlNodePtr field = label_values.nodes[label_index];
            //Get Label:
            xPathQuery label_Header_q = query(field, "/th", &err);
            if(label_Header_q.count){
                xmlNodePtr header = label_Header_q.nodes[0];
                char * message = (char*)header->children[0].content;
                if(strcmp("Monthly plan allowance", message) == 0){
                    
                    xPathQuery label_value_q = query(field, "/td", &err);
                    if(label_value_q.count){
                        xmlNodePtr value = label_value_q.nodes[0];
                        char *text = (char*)value->children[0].content;
                        //E.g. "200GB*, then slowed"
                        //Need to convert this to MB
                        int v;
                        
                        //TODO: Assuming GB, is this safe?
                        if(sscanf(text, "%d", &v)){
                            result->plan = v * 1000;
                        }else{
                            err = UMError_CouldNotParsePlanSize;
                        }
                    }
                    doneQuery(label_value_q);
                    found_all_labels = 1;
                }
            }
            doneQuery(label_Header_q);
            
        }
        if(!result->plan){
            err = UMError_CouldNotParsePlanSize;
        }
        doneQuery(label_values);
    } else if(q.count == 0) {
        err = UMError_TableNotFound;
        xPathQuery errors = query((xmlNodePtr)doc, "//span[@class = 'desktopError']/p", &err);
        int error_id;
        if(errors.count){
            for(error_id=0;error_id<errors.count;error_id++){
                if(errors.nodes[error_id]->children != NULL){
                    char * message = (char*)errors.nodes[error_id]->children[0].content;
                    if(strcmp("All items marked with an asterisk ( * ) are required to be filled out.", message) == 0){
                        
                    }else if(strcmp("Your username/password combination is incorrect or incomplete.", message) == 0){
                        err = UMError_InvalidPassword;
                        break;
                    }else if(strcmp("Don't forget to check:", message) == 0){
                        //Useless error message.
                    }else{
                        printf("Unknown Error: %s\n", message);
                    }
                }
            }
        }else{
            //Bigpond has a "</>" in the account locked page, and I don't know what that means, so here we we'll do a string search:
            //for 'account has been temporarily locked'
            
            int b = str_str_l(buffer,"account has been temporarily locked", buffer_size);
            if(b != -1){
                err = UMError_AccountLocked;
            }
        }
        doneQuery(errors);
        //TODO: Check for errors, such as wrong password.
        
    } else {
        err = UMError_TooManyTablesFound;
    }
    
    doneQuery(q);
    //TODO: find usage limits, account information.
    
    xmlFreeDoc(doc);
    return err;
}