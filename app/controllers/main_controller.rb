# deutsche Übersetzung der Monatesnamen:

#class Date
# remove MONTHNAMES
# MONTHNAMES = Array.new('Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember')
 
 #MONTHNAMES.replace([nil] + %w(Januar Februar März April Mai Juni Juli August September Oktober November Dezember) )
#end

class MainController < ApplicationController

  # nutzer-login:
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
    erste_einnahme = Gain.find(:first, :order => "datum ASC", :conditions => ['geloescht = false']).datum
    erste_ausgabe = Expense.find(:first, :order => "datum ASC", :conditions => ['geloescht = false']).datum
    
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
  user_max = User.find_by_login('max').id.to_s
  user_hans = User.find_by_login('hans').id.to_s
  
  @summe_einnahmen_hans = 0
  @summe_einnahmen_max = 0
  
  # alle einnahmen im zeitraum abrechnen und summen bilden
  abr_einnahmen = Gain.find(:all, :conditions => ['geloescht=false and bezahlt=true'])
  abr_einnahmen.each do |x|
    if (x.datum >= dat) && (x.datum < dat_end)
      x.abgerechnet = true
      x.save
      if x.user_id == user_hans.to_i
  	  	@summe_einnahmen_hans += x.netto
  	  end
  	  if x.user_id == user_max.to_i
  	  	@summe_einnahmen_max += x.netto
  	  end
    end
  end 
    
  
  @summe_ausgaben_hans = 0
  @summe_ausgaben_max = 0
  
  # alle ausgaben im zeitraum abrechnen und summen bilden
  abr_ausgaben = Expense.find(:all, :conditions => ['geloescht=false and bezahlt=true'])
  abr_ausgaben.each do |x|
    if (x.datum >= dat) && (x.datum < dat_end)
      x.abgerechnet = true
      x.save
      if x.user_id == user_hans.to_i
  	  	@summe_ausgaben_hans += x.netto
  	  end
  	  if x.user_id == user_max.to_i
  	  	@summe_ausgaben_max += x.netto
  	  end
    end
  end  

  
  # gewinne
  @summe_gewinn_hans = @summe_einnahmen_hans - @summe_ausgaben_hans
  @summe_gewinn_max = @summe_einnahmen_max - @summe_ausgaben_max
  
  @expenses_hans = Expense.find(:all, :order => "datum DESC", :conditions => ["geloescht = false AND bezahlt = true AND datum >= '"+dat.to_s+"' AND datum < '"+dat_end.to_s+"' AND user_id = "+user_hans])
  @expenses_max = Expense.find(:all, :order => "datum DESC", :conditions => ["geloescht = false AND bezahlt = true AND datum >= '"+dat.to_s+"' AND datum < '"+dat_end.to_s+"' AND user_id = "+user_max])
  
  @gains_hans = Gain.find(:all, :order => "datum DESC", :conditions => ["geloescht = false AND bezahlt = true AND datum >= '"+dat.to_s+"' AND datum < '"+dat_end.to_s+"' AND user_id = "+user_hans])
  @gains_max = Gain.find(:all, :order => "datum DESC", :conditions => ["geloescht = false AND bezahlt = true AND datum >= '"+dat.to_s+"' AND datum < '"+dat_end.to_s+"' AND user_id = "+user_max])
    
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
  pdf.Cell(40,10,'Hans')
  pdf.Ln(5)
  pdf.SetFont('Arial','B',13)
  pdf.Cell(40,10,'Einnahmen: '+MoreMoney::Money.new(@summe_einnahmen_hans *100, 'EUR').format(:with_thousands)+' EUR')
  pdf.Ln(5)
  pdf.Cell(40,10,'Ausgaben: '+MoreMoney::Money.new(@summe_ausgaben_hans *100, 'EUR').format(:with_thousands)+' EUR')
  pdf.Ln(5)
  pdf.Cell(40,10,'Gewinn: '+MoreMoney::Money.new(@summe_gewinn_hans *100, 'EUR').format(:with_thousands)+' EUR')
  pdf.Ln(20)
  
  pdf.SetFont('Arial','B',14)
  pdf.Cell(40,10,'Max')
  pdf.Ln(5)
  pdf.SetFont('Arial','B',13)
  pdf.Cell(40,10,'Einnahmen: '+MoreMoney::Money.new(@summe_einnahmen_max *100, 'EUR').format(:with_thousands)+' EUR')
  pdf.Ln(5)
  pdf.Cell(40,10,'Ausgaben: '+MoreMoney::Money.new(@summe_ausgaben_max *100, 'EUR').format(:with_thousands)+' EUR')
  pdf.Ln(5)
  pdf.Cell(40,10,'Gewinn: '+MoreMoney::Money.new(@summe_gewinn_max *100, 'EUR').format(:with_thousands)+' EUR')
  pdf.Ln(20)
  
  pdf.Cell(40,10,'Differenz: '+MoreMoney::Money.new( ((@summe_gewinn_hans - @summe_gewinn_max).abs / 2) *100, 'EUR').format(:with_thousands)+' EUR')
  pdf.Ln(20)
  
  # einnahmen hans
  pdf.SetFont('Arial','B',14)
  pdf.Cell(40,10,'alle Einnahmen Hans')
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
  
  @gains_hans.each do |gain| 
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
  
  # einnahmen max
  pdf.SetFont('Arial','B',14)
  pdf.Cell(40,10,'alle Einnahmen Max')
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
  
  @gains_max.each do |gain| 
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
  
  # ausgaben hans
  pdf.SetFont('Arial','B',14)
  pdf.Cell(40,10,'alle Ausgaben')
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
  
  @expenses_hans.each do |expense| 
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
  
  # ausgaben max
  pdf.SetFont('Arial','B',14)
  pdf.Cell(40,10,'alle Ausgaben')
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
  
  @expenses_max.each do |expense| 
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
  pdf.Output("public/abrechnung_"+dats_input+".pdf")
  pdf.Ln(10)
  
  render '/main/abrechnung'
  end
  
  
  	
  def abrechnung_pdf
    
    dats_input = CGI::unescape(params[:id])
    
    # anpassung an browser   
    if @request.env['HTTP_USER_AGENT'] =~ /msie/i
		@headers['Pragma'] = ''
		@headers['Cache-Control'] = ''
	else
		@headers['Pragma'] = 'no-cache'
		@headers['Cache-Control'] = 'no-cache, must-revalidate'
	end
    
    # datei an nutzer schicken
  	send_file "public/abrechnung_"+dats_input+".pdf", :filename => "abrechnung_"+dats_input+".pdf", :type => "application/pdf"
  	
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
	

end
