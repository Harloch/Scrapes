require 'mechanize'
require 'nokogiri'
require 'csv'

$crawler = Mechanize.new
host_url = 'http://www.vitals.com'

def writetoCSV w_arr, mode
	h_keys = [
		[
			'Overall Rating', 'Total Rating', 'Total Reviews', 'Ease of Appointment', 'Promptness', 'Courteous Staff',
			'Accurate Diagnosis', 'Bedside Manner', 'Spends Time with Me', 'Follows Up After Visit', 'Average Wait',
			'Personal Review Rating', 'Personal Review Title', 'Personal Review Info', 'Personal Ease of Appointment',
			'Personal Promptness', 'Personal Courteous Staff', 'Personal Accurate Diagnosis', 'Personal Bedside Manner',
			'Personal Spends Time With Me', 'Personal Follows Up After Visit'
		],
		[
			'Category', 'Cities', 'Doctor Name', 'Rating', 'Type', 'Years Experience',
			'Status', 'Where', 'Street', 'City', 'State', 'Zip', 'Specialty', 'Specialty Expertise',
			'Certifications', 'Education', 'Education Score', 'Appointments', 'Associations', 'Affiliations'
		]
	]
	fn = (mode == 1 ? 'without_' : '') + 'review.csv'
	CSV.open(fn, 'w+') do |csv|
		csv << h_keys[mode]
		w_arr.each do |row|
			csv << row
		end
	end
end

def addApples p_str
	str = p_str
	str['current '] = ''
	str = str.capitalize + ' Apple(s)'
	return str
end

class DoctorProfile
	def setprofilelink p_link
		@link = p_link
	end

	def setcategory p_category
		@category = p_category
	end

	def setcities p_city
		@city = p_city
	end

	def getprofilewihtoutreview
		profile_page = $crawler.get(@link) # whole profile page content
		header_info_group = profile_page.search('div.main-content > div.container > section > div.profile-header div.header-info-group')
		name = ''; rating = ''; type = ''; experience = ''; status = ''; where = ''; street = ''; city = ''; state = ''; zipcode = ''
		if header_info_group and header_info_group.count != 0
			name_degree_info = header_info_group.search('div.mobile-header-content > h1 > a') # name and degree
			if name_degree_info and name_degree_info.count != 0
				if name_degree_info.search('span.degree') and name_degree_info.search('span.degree').count != 0
					name_degree_info.search('span.degree').first.content = ''
				end
				name = name_degree_info.text.strip
			end
			rating_info = header_info_group.search('div.upper-rating-wrapper  div.rating-overview  span:first-child') # rating
			if rating_info and rating_info.count != 0
				rating = rating_info.first.text.strip
			end
			body_info = header_info_group.search('div.info-body')
			if body_info and body_info.count != 0
				type_exper_status = body_info.search('div.provider-details') # type, experience, status
				if type_exper_status and type_exper_status.count != 0
					if type_exper_status.search('a') and type_exper_status.search('a').count != 0 # remove video profile
						type_exper_status.search('a').remove
					end
					if type_exper_status.search('span') and type_exper_status.search('span').count != 0 # status
						status = type_exper_status.search('span').text.strip
						type_exper_status.search('span').first.content = '' 
					end
					if type_exper_status.search('strong') and type_exper_status.search('strong').count != 0 # type
						type = type_exper_status.search('strong').text.strip
						type_exper_status.search('strong').first.content = ''
					end
					experience = type_exper_status.text.strip
				end
				location_info = body_info.search('div.provider-location > div.address-block > address') # location
				if location_info and location_info.count != 0
					if location_info.search('span.neighborhood') # where
						where = location_info.search('span.neighborhood').text.strip
					end
					if location_info.search('span[itemprop=streetAddress]') # street
						street = location_info.search('span[itemprop=streetAddress]').text.strip
					end
					if location_info.search('span[itemprop=addressLocality]') # city
						city = location_info.search('span[itemprop=addressLocality]').text.strip
					end
					if location_info.search('span[itemprop=addressRegion]') # state
						state = location_info.search('span[itemprop=addressRegion]').text.strip
					end
					if location_info.search('span[itemprop=postalCode]') # zipcode
						zipcode = location_info.search('span[itemprop=postalCode]').text.strip
					end
				end
			end
		end

		main_info_group = profile_page.search('div.main-content > div.container > section > div.content > div.main')
		specialty = ''; sp_expertise = ''; certifications = ''
		if main_info_group and main_info_group.count != 0
			specialties_info = main_info_group.search('div.specialties') # specialty, specialty expertise, certification
			if specialties_info and specialties_info.count != 0
				specialty_info = specialties_info.search('table.specialty tbody')
				if specialty_info and specialty_info.count != 0
					if specialty_info.search('tr td:first-child') # specialty
						specialty_info.search('tr td:first-child').each_with_index do |specialty_item, index|
							specialty += (index == 0 ? '' : "\n") + specialty_item.text.strip
						end
					end
					if specialty_info.search('tr td:last-child') # certifications
						specialty_info.search('tr td:last-child').each_with_index do |cert_item, index|
							certifications += (index == 0 ? '' : "\n") + cert_item.text.strip
						end
					end
				else
					specialty_info = specialties_info.search('p')
					if specialty_info and specialty_info.count != 0
						cert_specialty = specialty_info.text.strip.split(' is ').last.split(' in ')
						tmp_cert = cert_specialty.first
						tmp_cert = tmp_cert.capitalize
						spec_arr = cert_specialty.last
						spec_arr['.'] = ''
						spec_arr = spec_arr.split(' and ')
						if spec_arr and spec_arr.count != 0
							spec_arr.each_with_index do |specialty_item, index|
								specialty += (index == 0 ? '' : "\n") + specialty_item
								certifications += (index == 0 ? '' : "\n") + tmp_cert
							end
						end
					end
				end
				sp_expertise_info = specialties_info.search('table.truncated tbody')
				if sp_expertise_info and sp_expertise_info.count != 0
					if sp_expertise_info.search('tr td:first-child')
						sp_expertise_info.search('tr td:first-child').each_with_index do |sp_exp_item, index|
							sp_expertise += (index == 0 ? '' : "\n") + sp_exp_item.text.strip
						end						
					end
				else
					sp_expertise_info = specialties_info.search('ul.list-dashed > li')
					if sp_expertise_info and sp_expertise_info.count != 0
						sp_expertise_info.each_with_index do |sp_exp_item, index|
							if index > 0
								sp_expertise += (index == 1 ? '' : "\n") + sp_exp_item.text.strip
							end
						end
					end
				end
			end
		end
		#credential link
		cred_link = profile_page.search('div.main-content > div.container > section > div.desktop-tabs-container > ul.nav-tabs > li:nth-child(3) > a')
		education = ''; education_score = ''; appointments = ''; associations = ''; affiliations = ''
		if cred_link and cred_link.count > 0
			cred_link = cred_link.first.attributes["href"].value
			cred_info = $crawler.get(cred_link).search('div.main-content > div.container > section > div.content > div.main')
			if cred_info and cred_info.count > 0
				edu_info = cred_info.search('div.education > table tbody tr')
				if edu_info and edu_info.count != 0
					edu_info.each_with_index do |edu_item, index|
						education += (index == 0 ? '' : "\n") + edu_item.search('td:first-child strong').text.strip
						edu_score_info = edu_item.search('td:nth-child(2) > ul.score > li:first-child')
						if edu_score_info and edu_score_info.count != 0
							edu_score_info = edu_score_info.first.attributes["class"].value
							edu_score_info['current'] = ''
							edu_score_info = edu_score_info.split(' ').last.capitalize
							education_score += (index == 0 ? '' : "\n") + edu_score_info + ' Apple(s)'
						else
							education_score = 'No Apple'
						end
					end
				end
				app_ass_info = cred_info.search('div.awards > table tbody')
				count = app_ass_info.count
				if app_ass_info and count != 0
					app_info = false; ass_info = false
					if count == 1
						ass_info = app_ass_info.last
					elsif count > 1
						ass_info = app_ass_info.last
						app_info = app_ass_info[-2]
					end
					if app_info
						if app_info.search('tr td') and app_info.search('tr td').count != 0
							app_info.search('tr td').each_with_index do |app_item, index|
								if app_item.text.strip! != nil
									app_item = app_item.text.strip!.gsub /\t/, ' '
								end
								appointments += (index == 0 ? '' : "\n") + app_item
							end
						end
					end
					if ass_info
						if ass_info.search('tr td') and  ass_info.search('tr td').count != 0
							ass_info.search('tr td').each_with_index do |ass_item, index|
								associations += (index == 0 ? '' : "\n") + ass_item.text.strip
							end
						end
					end
				end
				affiliation_info = cred_info.search('div.affiliations div.affiliations-body > li > div.hospital-info > strong')
				if affiliation_info and affiliation_info.count != 0
					affiliation_info.each_with_index do |aff_item, index|
						affiliations += (index == 0 ? '' : "\n") + aff_item.text.strip
					end
				end
			end
		end

		return [@category, @city, name, rating, type, experience, status, where, street, city, state, zipcode, specialty, sp_expertise, certifications, education, education_score, appointments, associations, affiliations]
	end

	def getprofilereview
		profile_page = $crawler.get @link
		p_review_link = profile_page.search 'div.main-content > div.container > section > div > ul.nav-tabs > li:nth-child(2) > a'
		if p_review_link and p_review_link.count != 0			
			p_review_link = p_review_link.first.attributes["href"].value
			review_page = $crawler.get p_review_link # Patient Reviews Content
			o_rating = ''; t_rating = ''; t_review = ''; ease_app = ''; prompt = ''; c_staff = ''; accurate = ''
			beside_manner = ''; spends_time = ''; follow_up = ''; average_wait = ''
			per_r_rating = ''; per_r_title = ''; per_r_desc = ''; per_e_app = ''; per_prompt = ''
			per_c_staff = ''; per_a_diagnosis = ''; per_b_manner = ''; per_s_time = ''; per_follow_up = ''
			review_info = review_page.search 'div.main-content > div.container > section > div.content > div.main > div.reviews'
			if review_info and review_info.count != 0
				overall_info = review_info.search'div.overall > table tbody tr' # Overall Info
				if overall_info and overall_info.count != 0
					if overall_info.search 'td#overall_rating'
						o_rating = overall_info.search('td#overall_rating').first.search('div span:first-child')
						if o_rating and o_rating.count != 0
							o_rating = o_rating.text.strip
						end
					end
					if overall_info.search 'td#overall_total_ratings'
						t_rating = overall_info.search 'td#overall_total_ratings h3'
						if t_rating and t_rating.count != 0
							t_rating = t_rating.text.strip
						end
					end
					if overall_info.search 'td#overall_total_reviews'
						t_review = overall_info.search 'td#overall_total_reviews h3'
						if t_review and t_review.count != 0
							t_review = t_review.text.strip
						end
					end
				end
				summary_info = review_info.search 'div.summary > table > tbody > tr > td'
				if summary_info and summary_info.count > 1
					t_rating_group_info = summary_info[-2].search 'table tbody tr'
					if t_rating_group_info and t_rating_group_info.count != 0
						if t_rating_group_info[0].search('td:last-child ul > li').count != 0
							ease_app = t_rating_group_info[0].search('td:last-child ul > li').first.attributes['class'].value
							ease_app = addApples ease_app
						end
						if t_rating_group_info[1].search('td:last-child ul > li').count != 0
							prompt = t_rating_group_info[1].search('td:last-child ul > li').first.attributes['class'].value
							prompt = addApples prompt
						end
						if t_rating_group_info[2].search('td:last-child ul > li').count != 0
							c_staff = t_rating_group_info[2].search('td:last-child ul > li').first.attributes['class'].value
							c_staff = addApples c_staff
						end
						if t_rating_group_info[3].search('td:last-child ul > li').count != 0
							accurate = t_rating_group_info[3].search('td:last-child ul > li').first.attributes['class'].value
							accurate = addApples accurate
						end
					end
					
					t_review_group_info = summary_info[-1].search 'table tbody tr'
					if t_review_group_info and t_review_group_info.count > 2
						if t_review_group_info[0].search('td:last-child ul > li').count != 0
							beside_manner = t_review_group_info[0].search('td:last-child ul > li').first.attributes["class"].value
							beside_manner = addApples beside_manner
						end
						if t_review_group_info[1].search('td:last-child ul > li').count != 0
							spends_time = t_review_group_info[1].search('td:last-child ul > li').first.attributes["class"].value
							spends_time = addApples spends_time
						end
						if t_review_group_info[2].search('td:last-child ul > li').count != 0
							follow_up = t_review_group_info[2].search('td:last-child ul > li').first.attributes["class"].value
							follow_up = addApples follow_up
						end
						if t_review_group_info.count == 4
							if t_review_group_info[3].search('td:last-child').count != 0
								average_wait = t_review_group_info[3].search('td:last-child').text.strip								
							end
						end
					end
				end
				personal_info_group = review_info.search('div#reviewspane > div.review')
				if personal_info_group and personal_info_group.count != 0
					personal_info_group.each_with_index do |personal_info, index|
						tmp_rating = personal_info.search('div.rating > span:first-child ul > li').first.attributes["class"].value
						per_r_rating += (index == 0 ? '' : "\n--------------\n") + addApples(tmp_rating)
						per_r_title += (index == 0 ? '' : "\n--------------\n") + personal_info.search('div.rating > span.summary').first.text.strip
						per_r_desc += (index == 0 ? '' : "\n--------------\n") + personal_info.search('p.description').text.strip

						qtip_id = personal_info.search('div.rating > a.qtipit')
						if qtip_id and qtip_id.count != 0
							# qtip_id = qtip_id.first.attributes["data-pop-element"].value
							per_r_details = personal_info.search('div:nth-child(3) > ul > li > ul > li')
							per_r_details_cnt = per_r_details.count

							if per_r_details and per_r_details_cnt == 8
								tmp_e_app = per_r_details[1].attributes["class"].value
								per_e_app += (index == 0 ? '' : "\n--------------\n") + addApples(tmp_e_app)

								tmp_prompt = per_r_details[2].attributes["class"].value
								per_prompt += (index == 0 ? '' : "\n--------------\n") + addApples(tmp_prompt)
								
								tmp_c_staff = per_r_details[3].attributes["class"].value
								per_c_staff += (index == 0 ? '' : "\n--------------\n") + addApples(tmp_c_staff)
								
								tmp_a_diagnosis = per_r_details[4].attributes["class"].value
								per_a_diagnosis += (index == 0 ? '' : "\n--------------\n") + addApples(tmp_a_diagnosis)

								tmp_b_manner = per_r_details[5].attributes["class"].value
								per_b_manner += (index == 0 ? '' : "\n--------------\n") + addApples(tmp_b_manner)

								tmp_s_time = per_r_details[6].attributes["class"].value
								per_s_time += (index == 0 ? '' : "\n--------------\n") + addApples(tmp_s_time)

								tmp_follow_up = per_r_details[7].attributes["class"].value
								per_follow_up += (index == 0 ? '' : "\n--------------\n") + addApples(tmp_follow_up)
							end
						end
					end
				end
			end

			return [
				o_rating, t_rating, t_review, ease_app, prompt, c_staff, accurate,
				beside_manner, spends_time, follow_up, average_wait,
				per_r_rating, per_r_title, per_r_desc,
				per_e_app, per_prompt, per_c_staff, per_a_diagnosis, per_b_manner, per_s_time, per_follow_up
			]
		end		
	end
end

# Start Scraping from location Page http://www.vitals.com/locations
location_page = $crawler.get host_url + '/locations'
category_columns = location_page.search 'div.main-content div.location-column'

if category_columns and category_columns.count != 0
	doctor_review_arr = []
	doctor_wo_review_arr = []
	profile_info_arr = []
	category_columns.each_with_index do |category_column, index|
		category_items = category_column.search('ul > li > a')
		if category_items and category_items.count != 0
			category_items.each do |category_item|
				category_name = category_item.text.strip + (index < 3 ? ' in Specialty by Location' : ' in Group Practice by Location')
				state_city_links = (index < 3 ? host_url : '') + category_item.attributes["href"].value
				states_cities_page = $crawler.get state_city_links
				state_name = ''; city_name = ''
				if index < 3
					states_list = states_cities_page.search 'div.main-content div div.insurance > ul > li:first-child a'
					if states_list and states_list.count != 0
						states_list.each do |state_item|
							state_name = state_item.text.strip
							cities_link = state_item.attributes["href"].value
							cities_page = $crawler.get host_url + cities_link
							cities_list = cities_page.search 'div.main-content div div.specialists > div.column-list > ul > li > ul > li a'
							if cities_list and cities_list.count
								cities_list.each do |city_item|
									city_name = city_item.text.strip
									specialists_link = city_item.attributes["href"].value
									specialists_page = $crawler.get specialists_link
									profile_links = specialists_page.search 'div#results-content > div.serplist-listing > div.serplist-listing-row:nth-child(2) a.serplist-listing-cta-profile'
									if profile_links and profile_links.count != 0
										profile_links.each do |profile_link_item|
											profile_info_arr << {
												:category_name => category_name,
												:cities => city_name + ' in ' + state_name,
												:profile_link => profile_link_item.attributes["href"].value
											}
											p profile_info_arr.last
										end
									end
								end
							end
						end
					end
				else
					state_name = category_name
					cities_list = states_cities_page.search 'div#navigation_content ul > li > ul > li a'
					if cities_list and cities_list.count != 0
						cities_list.each do |city_item|
							city_name = city_item.text.strip
							groups_page = $crawler.get city_item.attributes["href"].value
							group_links = groups_page.search 'div#results_array > div.results_display > div.content > a.profile'
							if group_links and group_links.count != 0
								group_links.each do |group_item|
									doctors_page = $crawler.get group_item.attributes["href"].value
									profile_links = doctors_page.get 'div#section_doctors > table tbody tr > td.review > a:last-child'
									if profile_links and profile_links.count != 0
										profile_links.each do |profile_link_item|
											profile_info_arr << {
												:category_name => category_name,
												:cities => city_name + ' in ' + state_name,
												:profile_link => profile_link_item.attributes["href"].value
											}
											p profile_info_arr.last
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
	if profile_info_arr.count > 0
		merged_profile_info_arr = []
		profile_info_arr.each_with_index do |profile_info, index|
			if index == 0
				merged_profile_info_arr << profile_info
			else
				merged_profile_info_arr.each do |merged_profile_info|
					if merged_profile_info[:profile_link] == profile_info[:profile_link]
						merged_profile_info[:category_name] += "\n" + profile_info[:category_name]
						merged_profile_info[:cities] += "\n" + profile_info[:cities]
						break
					end
				end
			end
		end

		if merged_profile_info_arr.count > 0
			doctor_profile = DoctorProfile.new
			merged_profile_info_arr.each do |profile_info|
				doctor_profile.setcategory profile_info[:category_name]
				doctor_profile.setcities profile_info[:cities]
				doctor_profile.setprofilelink profile_info[:profile_link]
				doctor_review_arr << doctor_profile.getprofilereview
				doctor_wo_review_arr << doctor_profile.getprofilewihtoutreview				
			end
		end
	end
	if doctor_review_arr.count != 0
		writetoCSV doctor_review_arr, 0
	end
	if doctor_wo_review_arr.count != 0
		writetoCSV doctor_wo_review_arr, 1
	end
end