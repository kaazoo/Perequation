class MainController < ApplicationController

  # user login:
  include AuthenticatedSystem
  #before_filter :login_required


  # pdf-generierung
  #require "htmldoc"
  require 'fpdf'

  # Klasse für Geld und Kommadarstellung:
  require 'more_money'
  MoreMoney::Money.add_currency({:code => 'EUR', :description => 'euro'})

  def menue
		
	# ist nutzer eingeloggt?
  	if logged_in?
      @nutzer = current_user
  	  @logout_link = "<a href=\"/main/logout\">ausloggen</a>"
  	end
  		
  end
	
  def abrechnungen
    erste_einnahme = Gain.find(:first, :order => "datum ASC", :conditions => ['geloescht = ?', false]).datum
    erste_ausgabe = Expense.find(:first, :order => "datum ASC", :conditions => ['geloescht = ?', false]).datum
    
    if erste_einnahme < erste_ausgabe
      min = erste_einnahme
    else
      min = erste_ausgabe
    end
    
    @erstes_jahr = min.year
    @erster_monat = min.month
    
  end
	
  
  def abrechnen
    
  # paramater extrahieren
  dats_input = CGI::unescape(params[:id])
  dats = dats_input.split(/,\s*/)
  dat = Date.strptime(dats[0])
  dat_end = Date.strptime(dats[1])
  
  @month_name = Date.strptime(dat.to_s).strftime("%B")
  @year = Date.strptime(dat.to_s).strftime("%Y")
  
  
  # user-ids aus db holen
  first_user_id = User.find_by_login(APP_CONFIG['pq_first_user']).id
  second_user_id = User.find_by_login(APP_CONFIG['pq_second_user']).id
  
  
  @summe_einnahmen_first_user = 0
  @summe_einnahmen_second_user = 0
  
  # alle einnahmen im zeitraum abrechnen und summen bilden
  abr_einnahmen = Gain.find(:all, :conditions => ['geloescht=? and bezahlt=?', false, true])
  abr_einnahmen.each do |x|
    if (x.datum >= dat) && (x.datum < dat_end)
      x.abgerechnet = true
      x.save
      if x.user_id == first_user_id
  	  	@summe_einnahmen_first_user += x.netto
  	  end
      if x.user_id == second_user_id
  	  	@summe_einnahmen_second_user += x.netto
  	  end
    end
  end 
    
  
  @summe_ausgaben_first_user = 0
  @summe_ausgaben_second_user = 0
  
  # alle ausgaben im zeitraum abrechnen und summen bilden
  abr_ausgaben = Expense.find(:all, :conditions => ['geloescht=? and bezahlt=?', false, true])
  abr_ausgaben.each do |x|
    if (x.datum >= dat) && (x.datum < dat_end)
      x.abgerechnet = true
      x.save
      if x.user_id == first_user_id
  	  	@summe_ausgaben_first_user += x.netto
  	  end
  	  if x.user_id == second_user_id
  	  	@summe_ausgaben_second_user += x.netto
  	  end
    end
  end  

  
  # gewinne
  @summe_gewinn_first_user = @summe_einnahmen_first_user - @summe_ausgaben_first_user
  @summe_gewinn_second_user = @summe_einnahmen_second_user - @summe_ausgaben_second_user
  
  @expenses_first_user = Expense.find(:all, :order => "datum DESC", :conditions => ["geloescht = ? AND bezahlt = ? AND datum >= '"+dat.to_s+"' AND datum < '"+dat_end.to_s+"' AND user_id = "+first_user_id.to_s, false, true])
  @expenses_second_user = Expense.find(:all, :order => "datum DESC", :conditions => ["geloescht = ? AND bezahlt = ? AND datum >= '"+dat.to_s+"' AND datum < '"+dat_end.to_s+"' AND user_id = "+second_user_id.to_s, false, true])
  
  @gains_first_user = Gain.find(:all, :order => "datum DESC", :conditions => ["geloescht = ? AND bezahlt = ? AND datum >= '"+dat.to_s+"' AND datum < '"+dat_end.to_s+"' AND user_id = "+first_user_id.to_s, false, true])
  @gains_second_user = Gain.find(:all, :order => "datum DESC", :conditions => ["geloescht = ? AND bezahlt = ? AND datum >= '"+dat.to_s+"' AND datum < '"+dat_end.to_s+"' AND user_id = "+second_user_id.to_s, false, true])
    
  # neue abrechnung erstellen
  # ERSTMA NICH
  st = Statement.new
  st.erstellungsdatum = Date.today.to_s
  st.name = dats_input
  st.save
  
  # pdf generierung
  pdf=FPDF.new
  pdf.AddPage
  pdf.SetFont('Arial','B',16)
  pdf.Cell(40,10,'Abrechnung '+@month_name+' '+@year)
  pdf.Ln(20)
  pdf.SetFont('Arial','B',11)
  pdf.Cell(40,10,'Alle Werte sind in Netto.')
  pdf.Ln(20)
  
  # uebersicht
  pdf.SetFont('Arial','B',14)
  pdf.Cell(40,10,APP_CONFIG['pq_first_user'])
  pdf.Ln(5)
  pdf.SetFont('Arial','B',13)
  pdf.Cell(40,10,'Einnahmen: '+MoreMoney::Money.new(@summe_einnahmen_first_user *100, 'EUR').format(:with_thousands)+' EUR')
  pdf.Ln(5)
  pdf.Cell(40,10,'Ausgaben: '+MoreMoney::Money.new(@summe_ausgaben_first_user *100, 'EUR').format(:with_thousands)+' EUR')
  pdf.Ln(5)
  pdf.Cell(40,10,'Gewinn: '+MoreMoney::Money.new(@summe_gewinn_first_user *100, 'EUR').format(:with_thousands)+' EUR')
  pdf.Ln(20)
  
  pdf.SetFont('Arial','B',14)
  pdf.Cell(40,10,APP_CONFIG['pq_second_user'])
  pdf.Ln(5)
  pdf.SetFont('Arial','B',13)
  pdf.Cell(40,10,'Einnahmen: '+MoreMoney::Money.new(@summe_einnahmen_second_user *100, 'EUR').format(:with_thousands)+' EUR')
  pdf.Ln(5)
  pdf.Cell(40,10,'Ausgaben: '+MoreMoney::Money.new(@summe_ausgaben_second_user *100, 'EUR').format(:with_thousands)+' EUR')
  pdf.Ln(5)
  pdf.Cell(40,10,'Gewinn: '+MoreMoney::Money.new(@summe_gewinn_second_user *100, 'EUR').format(:with_thousands)+' EUR')
  pdf.Ln(20)
  
  pdf.Cell(40,10,'Differenz: '+MoreMoney::Money.new( ((@summe_gewinn_first_user - @summe_gewinn_second_user).abs / 2) *100, 'EUR').format(:with_thousands)+' EUR')
  pdf.Ln(20)
  
  # einnahmen first_user
  pdf.SetFont('Arial','B',14)
  pdf.Cell(40,10,'alle Einnahmen '+APP_CONFIG['pq_first_user'])
  pdf.Ln(10)
  pdf.SetFont('Arial','B',11)
  
  pdf.Cell(45, 7, 'Name', 1)
  pdf.Cell(22, 7, 'Datum', 1)
  pdf.Cell(35, 7, 'Netto', 1)
  #pdf.Cell(30, 7, 'Brutto', 1)
  pdf.Cell(15, 7, 'MwSt', 1)
  pdf.Cell(30, 7, 'Eintragsdatum', 1)
  pdf.Cell(20, 7, 'Person', 1)
  
  pdf.Ln()
  
  @gains_first_user.each do |gain| 
	    pdf.Cell(45, 6, gain.name, 1)
	    
	    old_date = gain.datum.to_s
	    pdf.Cell(22, 6, "#{old_date[8,2]}.#{old_date[5,2]}.#{old_date[0,4]}", 1)
	    
	    pdf.Cell(35, 6, ((gain.netto * 100).round/100.0).to_s.gsub(/\./,',')+' EUR', 1)
	    
	    #pdf.Cell(30, 6, ((gain.brutto * 100).round/100.0).to_s.gsub(/\./,',')+' EUR', 1)
	    
	    pdf.Cell(15, 6, (gain.mwst * 100).to_i.to_s + " %", 1)
	    
	    old_date = gain.eintragsdatum.to_s
	    pdf.Cell(30, 6, "#{old_date[8,2]}.#{old_date[5,2]}.#{old_date[0,4]}", 1)
	    
	    pdf.Cell(20, 6, User.find(gain.user_id).name, 1)
	    pdf.Ln()
  end
  
  pdf.Ln(20)
  
  # einnahmen second_user
  pdf.SetFont('Arial','B',14)
  pdf.Cell(40,10,'alle Einnahmen '+APP_CONFIG['pq_second_user'])
  pdf.Ln(10)
  pdf.SetFont('Arial','B',11)
  
  pdf.Cell(45, 7, 'Name', 1)
  pdf.Cell(22, 7, 'Datum', 1)
  pdf.Cell(35, 7, 'Netto', 1)
  #pdf.Cell(30, 7, 'Brutto', 1)
  pdf.Cell(15, 7, 'MwSt', 1)
  pdf.Cell(30, 7, 'Eintragsdatum', 1)
  pdf.Cell(20, 7, 'Person', 1)
  
  pdf.Ln()
  
  @gains_second_user.each do |gain| 
	    pdf.Cell(45, 6, gain.name, 1)
	    
	    old_date = gain.datum.to_s
	    pdf.Cell(22, 6, "#{old_date[8,2]}.#{old_date[5,2]}.#{old_date[0,4]}", 1)
	    
	    pdf.Cell(35, 6, ((gain.netto * 100).round/100.0).to_s.gsub(/\./,',')+' EUR', 1)
	    
	    #pdf.Cell(30, 6, ((gain.brutto * 100).round/100.0).to_s.gsub(/\./,',')+' EUR', 1)
	    
	    pdf.Cell(15, 6, (gain.mwst * 100).to_i.to_s + " %", 1)
	    
	    old_date = gain.eintragsdatum.to_s
	    pdf.Cell(30, 6, "#{old_date[8,2]}.#{old_date[5,2]}.#{old_date[0,4]}", 1)
	    
	    pdf.Cell(20, 6, User.find(gain.user_id).name, 1)
	    pdf.Ln()
  end
  
  pdf.Ln(20)
  
  # ausgaben first_user
  pdf.SetFont('Arial','B',14)
  pdf.Cell(40,10,'alle Ausgaben '+APP_CONFIG['pq_first_user'])
  pdf.Ln(10)
  pdf.SetFont('Arial','B',11)
  
  pdf.Cell(45, 7, 'Name', 1)
  pdf.Cell(22, 7, 'Datum', 1)
  pdf.Cell(35, 7, 'Netto', 1)
  #pdf.Cell(30, 7, 'Brutto', 1)
  pdf.Cell(15, 7, 'MwSt', 1)
  pdf.Cell(10, 7, 'Art', 1)
  pdf.Cell(30, 7, 'Eintragsdatum', 1)
  pdf.Cell(20, 7, 'Person', 1)
  
  pdf.Ln()
  
  @expenses_first_user.each do |expense| 
	    pdf.Cell(45, 6, expense.name, 1)
	    
	    old_date = expense.datum.to_s
	    pdf.Cell(22, 6, "#{old_date[8,2]}.#{old_date[5,2]}.#{old_date[0,4]}", 1)
	    
	    pdf.Cell(35, 6, ((expense.netto * 100).round/100.0).to_s.gsub(/\./,',')+' EUR', 1)
	    
	    #pdf.Cell(30, 6, ((expense.brutto * 100).round/100.0).to_s.gsub(/\./,',')+' EUR', 1)
	    
	    pdf.Cell(15, 6, (expense.mwst * 100).to_i.to_s + " %", 1)
	    
	    pdf.Cell(10, 6, expense.art[0,1], 1)
	    
	    old_date = expense.eintragsdatum.to_s
	    pdf.Cell(30, 6, "#{old_date[8,2]}.#{old_date[5,2]}.#{old_date[0,4]}", 1)
	    
	    pdf.Cell(20, 6, User.find(expense.user_id).name, 1)
	    pdf.Ln()
  end
  
  pdf.Ln(20)
  
  # ausgaben second_user
  pdf.SetFont('Arial','B',14)
  pdf.Cell(40,10,'alle Ausgaben '+APP_CONFIG['pq_second_user'])
  pdf.Ln(10)
  pdf.SetFont('Arial','B',11)
  
  pdf.Cell(45, 7, 'Name', 1)
  pdf.Cell(22, 7, 'Datum', 1)
  pdf.Cell(35, 7, 'Netto', 1)
  #pdf.Cell(30, 7, 'Brutto', 1)
  pdf.Cell(15, 7, 'MwSt', 1)
  pdf.Cell(10, 7, 'Art', 1)
  pdf.Cell(30, 7, 'Eintragsdatum', 1)
  pdf.Cell(20, 7, 'Person', 1)
  
  pdf.Ln()
  
  @expenses_second_user.each do |expense| 
	    pdf.Cell(45, 6, expense.name, 1)
	    
	    old_date = expense.datum.to_s
	    pdf.Cell(22, 6, "#{old_date[8,2]}.#{old_date[5,2]}.#{old_date[0,4]}", 1)
	    
	    pdf.Cell(35, 6, ((expense.netto * 100).round/100.0).to_s.gsub(/\./,',')+' EUR', 1)
	    
	    #pdf.Cell(30, 6, ((expense.brutto * 100).round/100.0).to_s.gsub(/\./,',')+' EUR', 1)
	    
	    pdf.Cell(15, 6, (expense.mwst * 100).to_i.to_s + " %", 1)
	    
	    pdf.Cell(10, 6, expense.art[0,1], 1)
	    
	    old_date = expense.eintragsdatum.to_s
	    pdf.Cell(30, 6, "#{old_date[8,2]}.#{old_date[5,2]}.#{old_date[0,4]}", 1)
	    
	    pdf.Cell(20, 6, User.find(expense.user_id).name, 1)
	    pdf.Ln()
  end

  # pdf abspeichern
  pdf.Output("public/"+APP_CONFIG['pq_pdf_prefix']+"_"+dats_input.gsub(',', '_')+".pdf")
  pdf.Ln(10)
  
  render '/main/abrechnung'
  end
  
  
  	
  def abrechnung_pdf
    
    dats_input = CGI::unescape(params[:id])
    
    # anpassung an browser   
    if request.env['HTTP_USER_AGENT'] =~ /msie/i
		headers['Pragma'] = ''
		headers['Cache-Control'] = ''
	else
		headers['Pragma'] = 'no-cache'
		headers['Cache-Control'] = 'no-cache, must-revalidate'
	end
    
    # datei an nutzer schicken
  	send_file "public/"+APP_CONFIG['pq_pdf_prefix']+"_"+dats_input.gsub(',', '_')+".pdf", :filename => APP_CONFIG['pq_pdf_prefix']+"_"+dats_input.gsub(',', '_')+".pdf", :type => "application/pdf"
  	
  end
  
    
  
  def login
    return unless request.post?
    self.current_user = User.authenticate(params[:login], params[:password])
    if logged_in?
      if params[:remember_me] == "1"
        self.current_user.remember_me
        cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
      end
      redirect_back_or_default(:controller => '/main', :action => 'menue')
      flash[:notice] = "Logged in successfully"
    end
  end


  def signup
    @user = User.new(params[:user])
    return unless request.post?
    @user.save!
    self.current_user = @user
    redirect_back_or_default(:controller => '/main', :action => 'menue')
    flash[:notice] = "Thanks for signing up!"
  rescue ActiveRecord::RecordInvalid
    render :action => 'signup'
  end
  
  
  def logout
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    flash[:notice] = "You have been logged out."
    redirect_back_or_default(:controller => '/main', :action => 'menue')
    #redirect_to '/'
  end


  def statistic_month
  
    if params[:date] == nil
      # start with last month 
      mydate = Date.today.last_month
      @startmonth = mydate.month
      @startyear = mydate.year
    else
      mydate = Date.parse(params[:date])
      @startmonth = mydate.month
      @startyear = mydate.year
    end
        
    # one month earlier
    @month_before = mydate.last_month.month
    @year_before = mydate.last_month.year
    
    # one month after
    @month_next = mydate.next_month.month
    @year_next = mydate.next_month.year
  
  end
  
  def statistic_year
  
    if params[:year] == nil
      mydate = Date.today
      @startyear = mydate.year
    else
      @startyear = params[:year].to_i
    end
        
    # one year earlier
    @year_before = @startyear - 1
    
    # one year after
    @year_next = @startyear + 1
  
  end

	
  def render_graph
    
    month = params[:m].to_i
    year = params[:y].to_i
    
    if (month > 0) && (year > 0)
      # get number of days in month
      numdays = Time::days_in_month(month, year)
    
      # generate arrays for month
      gains_arr = Array.new(numdays)
      gains_arr.fill(0)
      expenses_arr = Array.new(numdays)
      expenses_arr.fill(0)
    
      # first and last day of month
      first_day = year.to_s+"-"+month.to_s+"-01"
      last_day = year.to_s+"-"+month.to_s+"-"+numdays.to_s
    
      # add gains to array
      gains = Gain.find(:all, :conditions => { :datum => first_day..last_day })
      gains.each do |gain|
        datum = Date.parse(gain[:datum].to_s)
        gains_arr[datum.day] += gain[:netto]
      end
    
      # add expenses to array
      expenses = Expense.find(:all, :conditions => { :datum => first_day..last_day })
      expenses.each do |expense|
        datum = Date.parse(expense[:datum].to_s)
        expenses_arr[datum.day] += expense[:netto]
      end
    
      # render graph
      graph = Scruffy::Graph.new
      graph.title = Date::MONTHNAMES[month].to_s+" "+year.to_s
      graph.add(:line, t(:gains), gains_arr)
      graph.add(:line, t(:expenses), expenses_arr)
            
    elsif (month = 0) && (year > 0)
      # number of weeks in year
      numdays = 53
      
      # generate arrays for year
      gains_arr = Array.new(numdays)
      gains_arr.fill(0)
      expenses_arr = Array.new(numdays)
      expenses_arr.fill(0)
      
      # first and last day of year
      first_day = year.to_s+"-01-01"
      last_day = year.to_s+"-12-31"
    
      # add gains to array
      gains = Gain.find(:all, :conditions => { :datum => first_day..last_day })
      gains.each do |gain|
        datum = Date.parse(gain[:datum].to_s)
        week_of_year = datum.strftime("%W").to_i
        gains_arr[week_of_year] += gain[:netto]
      end
    
      # add expenses to array
      expenses = Expense.find(:all, :conditions => { :datum => first_day..last_day })
      expenses.each do |expense|
        datum = Date.parse(expense[:datum].to_s)
        week_of_year = datum.strftime("%W").to_i
        expenses_arr[week_of_year] += expense[:netto]
      end
            
      # render graph
      graph = Scruffy::Graph.new
      graph.title = year.to_s
      graph.add(:line, t(:gains), gains_arr)
      graph.add(:line, t(:expenses), expenses_arr)   
      
    end
    
    graph_blob = graph.render :size => [900,500], :as => 'PNG'
    send_data graph_blob, :filename => 'graph.png', :type => 'image/png', :disposition => 'inline'
 
  end



end
