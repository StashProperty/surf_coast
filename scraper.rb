require 'scraperwiki'
require 'rubygems'
require 'Faraday'
require 'Date'


start_date = (Date.today - 14).strftime("%d-%m-%Y")
date_scraped = Date.today.to_s

data_url = 'https://eplanning.surfcoast.vic.gov.au/Services/ReferenceService.svc/Get_PlanningRegister'
info_url = "https://eplanning.surfcoast.vic.gov.au/Public/ViewActivity.aspx?refid="


resp = Faraday.post(data_url) do |req|
    req.headers['content-type'] = 'application/JSON'

    req.body = '{"packet":[{"name":"iDisplayLength","value":1000},{"name":"bSearchable_0","value":true},{"name":"bSortable_0","value":true},{"name": "sSearch_1", "value": '+ start_date+ '},{"name":"mDataProp_1","value":"LodgedDate_STRING"},{"name":"bRegex_1","value":false},{"name":"bSearchable_1","value":true},{"name":"bSortable_1","value":true},{"name":"mDataProp_2","value":"DecisionDate_STRING"},{"name":"bRegex_2","value":false},{"name":"bSearchable_2","value":true},{"name":"bSortable_2","value":true},{"name":"mDataProp_3","value":"SiteAddress"},{"name":"bRegex_3","value":false},{"name":"bSearchable_3","value":true},{"name":"bSortable_3","value":false},{"name":"mDataProp_4","value":"ReasonForPermit"},{"name":"bRegex_4","value":false},{"name":"bSearchable_4","value":true},{"name":"bSortable_4","value":true},{"name":"mDataProp_5","value":"Ward"},{"name":"sSearch_5","value":""},{"name":"bRegex_5","value":false},{"name":"bSearchable_5","value":true},{"name":"bSortable_5","value":true},{"name":"mDataProp_6","value":"StatusName"},{"name":"bRegex_6","value":false},{"name":"bSearchable_6","value":true},{"name":"bSortable_6","value":false},{"name":"mDataProp_7","value":"Actions"},{"name":"bRegex_7","value":false},{"name":"bSearchable_7","value":true},{"name":"bSortable_7","value":true},{"name":"bRegex","value":false},{"name":"iSortCol_0","value":1},{"name":"sSortDir_0","value":"desc"},{"name":"iSortingCols","value":1}]}'
  end
  
raw = JSON.parse(resp.body)['d'].split("]")[0].delete("}").delete('"').delete("\\").gsub("null","nil").split("{")[2..-1]

puts "Found #{raw.length} rows"


raw.each do |row|
	record = {}
	parsed_row = row.split(",")
	record["date_scraped"] = date_scraped
	parsed_row.each do |field|
		key = field.split(":")[0]
		value = field.split(":")[1]
		case key
		when "ApplicationReference"
			record["council_reference"] = value
			record["info_url"] = info_url + value
		when "FullSiteAddress"
			record["address"] = value
		when "LodgedDate_STRING"
			record["date_received"] = value
		when "ReasonForPermit"
			record["description"] = value
		end
	end
	next if record.count < 5
	puts "Saving #{record['council_reference']}, #{record['address']}"
	ScraperWiki.save_sqlite(['council_reference'], record)
end
