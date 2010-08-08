# deutsche Übersetzung der Monatesnamen:
#class Date
# MONTHNAMES.replace([nil] + %w(Januar Februar März April Mai Juni Juli August September Oktober November Dezember) )
#end

class ExpensesController < ApplicationController

  # Klasse für Geld und Kommadarstellung:
  require 'more_money'
  MoreMoney::Money.add_currency({:code => 'EUR', :description => 'euro'})
  
  # nutzer-login:
  include AuthenticatedSystem
  before_filter :login_required
  
  # actions für die liste:
  def formular_liste
    case params[:which_action]
      when "Auswahl aufsummieren"
        auswahl_summe
      when "Auswahl abrechnen"
        auswahl_abrechnung
      else 
        list
        render :action => 'list'
    end
  end
  
  # summe der netto-beträge:
  def auswahl_summe
  	@summe_netto = @summe_brutto = 0
  	for aw in params[:auswahl] do
  	  if aw[1].to_i == 1
  	    expense = Expense.find(aw[0].to_i)
  	    @summe_netto += expense.netto
  	    @summe_brutto += expense.brutto
  	  end
  	end
  	render :partial => 'summe'
  end
  
  def auswahl_abrechnung
    #puts params
    
    # auswahl an partial-view senden:
    if params[:auswahl]
    @nicht_bezahlt = Array.new
    @bezahlt = Array.new
    
    @summe_netto = @summe_brutto = 0
    for aw in params[:auswahl] do
  	  if aw[1].to_i == 1
  	    expense = Expense.find(aw[0].to_i)
  	    # schon bezahlt?
  	    if expense.bezahlt == true
          @summe_netto += expense.netto
          @summe_brutto += expense.brutto
          @bezahlt << expense.id
        else
          @nicht_bezahlt << expense.id
        end
  	  end
  	end
	
    render :partial => 'abrechnung'
    # daten kommen aus flash-speicher vom view zurück:
    else
  	  @summe_netto = flash[:netto]
  	  @summe_brutto = flash[:brutto]
  	  @abrechnung_name = params[:abrechnung][:name]
  	  @abrechnung_bestehend = params[:abrechnung][:bestehend]
  	  @nicht_bezahlt = flash[:nicht_bezahlt]
  	  @bezahlt = flash[:bezahlt]
  	  if (@summe_netto != 0) && (@abrechnung_name != "") && (@abrechnung_bestehend != "")
  	    flash[:notice] = "Ung&uuml;ltige Eingabe"
  	    'list/all'
    	render :action => 'list'
  	  end
  	  if (@summe_netto != 0) && (@abrechnung_name != nil) && (@abrechnung_name != "")
  	  #if (@abrechnung_name != nil) && (@abrechnung_name != "")
  	    # TODO datenbankeinträge machen
  	    statement = Statement.new
  	    statement.name = @abrechnung_name
  	    statement.ausgaben_netto = @summe_netto
  	    statement.ausgaben_brutto = @summe_brutto
  	    statement.einnahmen_netto = 0
  	    statement.einnahmen_brutto = 0
  	    statement.gewinn_netto = 0
  	    statement.gewinn_brutto = 0
  	    statement.erstellungsdatum = Date.today
        statement.save
        
        for bz in @bezahlt do
  	      expense = Expense.find(bz.to_i)
	  	  expense.statement_id = statement.id
	  	  expense.abgerechnet = true
	  	  expense.save
  	    end
  	  
        #redirect_to :action => 'list/all'
  	  end
  	  # bestehende abrechnung erweitern:
      if (@summe_netto != 0) && (@abrechnung_bestehend != nil) && (@abrechnung_bestehend != "")
        statement = Statement.find(@abrechnung_bestehend)
  	    @abrechnung_name = statement.name
  	    statement.ausgaben_netto = @summe_netto
  	    statement.ausgaben_brutto = @summe_brutto
  	    statement.gewinn_netto = statement.einnahmen_netto - statement.ausgaben_netto
  	    statement.gewinn_brutto = statement.einnahmen_brutto - statement.ausgaben_brutto
        statement.save
        
        for bz in @bezahlt do
  	      expense = Expense.find(bz.to_i)
	  	  expense.statement_id = statement.id
	  	  expense.abgerechnet = true
	  	  expense.save
  	    end
  	  
        #redirect_to :action => 'list/all'
  	  end
      render :partial => 'abrechnung'
    end
  end


  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }


  def list
  
  	if params[:year] && params[:month]
  		@year = params[:year].to_i
  		@month = params[:month]
  	else
  		@year = Date.today.year
  		@month = Date.today.month.to_s
  	end
  	  		
  	if @month == '1'
  		@last_month = '12'
  		@next_month = '2'
  		@next_year = @year +1
  		@last_year = @year -1
  	elsif @month == '12'
  		@last_month = '11'
  		@next_month = '1'
  		@next_year = @year +1
  		@last_year = @year
  	else
  		@last_month = (@month.to_i) -1
  		@next_month = (@month.to_i) +1
  		@next_year = @year
  		@last_year = @year
  	end
  	
  	# fuehrende null
  	if @last_month.to_i < 10
  		@last_month = '0'+@last_month.to_i.to_s
  	end
  	if @next_month.to_i < 10
  		@next_month = '0'+@next_month.to_i.to_s
  	end
  	if @month.to_i < 10
  		@month = '0'+@month.to_i.to_s
  	end
  	
  	# zu strings konvertieren
  	@month = @month.to_s
  	@year = @year.to_s
  	
  	# monatsnamen
  	@month_name = Date.strptime(@year.to_s+'-'+@month+'-01').strftime("%B")
  	
    # alle oder nur eigene einträge anzeigen:
    case(params[:id])
      when "all"
      	#dat = (@year.to_s+'-'+@month.to_s+'-01').to.date
      	#puts @year.to_s+'-'+@month.to_s+'-01'
      	#puts @next_year.to_s+'-'+@next_month.to_s+'-01'
      	#puts @expenses = Expense.find(:all, :order => "datum DESC", :conditions => ["geloescht = false AND datum = (date('"+@year.to_s+"-"+@month.to_s+"-01') + interval '1 month')"])
      	@expenses = Expense.find(:all, :order => "datum DESC", :conditions => ["geloescht = false AND datum >= '"+@year.to_s+"-"+@month.to_s+"-01' AND datum < '"+@next_year.to_s+"-"+@next_month.to_s+"-01'"])
      	#@expense_pages, @expenses = paginate :expenses, :per_page => 30, :order => "datum DESC", :conditions => ["geloescht = false AND datum = (date('"+@year.to_s+"-"+@month.to_s+"-01') + interval '1 month')"]
      	#@expense_pages, @expenses = paginate :expenses, :per_page => 30, :order => "datum DESC", :conditions => ['geloescht = false AND year(datum) = '+@year.to_s+' AND month(datum) = '+@month.to_s]
      	# summe des aktuellen monats:
	  	@monat_netto = @monat_brutto = 0
	  	for expense in @expenses
          		@monat_netto += expense.netto
    	  		@monat_brutto += expense.brutto
	  	end
        
      when "future"
      	@expenses = Expense.find(:all, :order => "datum DESC", :conditions => ["geloescht = false AND abgerechnet = false AND bezahlt = false AND datum >= '"+@year.to_s+"-"+@month.to_s+"-01' AND datum < '"+@next_year.to_s+"-"+@next_month.to_s+"-01'"])
      	#@expense_pages, @expenses = paginate :expenses, :per_page => 30, :order => "datum DESC", :conditions => ['geloescht = false and abgerechnet = false and bezahlt = false']
      	# summe des aktuellen monats:
	  	@future_netto = @future_brutto = 0
	  	for expense in @expenses
        	@future_netto += expense.netto
    		@future_brutto += expense.brutto
	  	end
        
      else
      	@expenses = Expense.find(:all, :order => "datum DESC", :conditions => ["user_id = "+current_user.id.to_s+" AND geloescht = false AND abgerechnet = false AND datum >= '"+@year.to_s+"-"+@month.to_s+"-01' AND datum < '"+@next_year.to_s+"-"+@next_month.to_s+"-01'"])
      	#@expense_pages, @expenses = paginate :expenses, :per_page => 30, :order => "datum DESC", :conditions => ['user_id = '+current_user.id.to_s+' and geloescht = false and abgerechnet = false']
      	
      	# summen des aktuellen monats:
      	
      	@monat_netto_bezahlt = @monat_brutto_bezahlt = 0
      	#if (@expenses_bezahlt = Expense.find(:all, :order => "datum DESC", :conditions => ['user_id = '+current_user.id.to_s+' and geloescht = false AND abgerechnet = false AND bezahlt = true' ])) && (@expenses_bezahlt.length > 0)
      	if (@expenses_bezahlt = Expense.find(:all, :order => "datum DESC", :conditions => ["user_id = "+current_user.id.to_s+" AND geloescht = false AND abgerechnet = false AND bezahlt = true AND datum >= '"+@year.to_s+"-"+@month.to_s+"-01' AND datum < '"+@next_year.to_s+"-"+@next_month.to_s+"-01'"])) && (@expenses_bezahlt.length > 0)
		  	for expense in @expenses_bezahlt
	          		@monat_netto_bezahlt += expense.netto
	    	  		@monat_brutto_bezahlt += expense.brutto
	  		end
		end
	  	
	  	@monat_netto_unbezahlt = @monat_brutto_unbezahlt = 0
	  	#if (@expenses_unbezahlt = Expense.find(:all, :order => "datum DESC", :conditions => ['user_id = '+current_user.id.to_s+' and geloescht = false AND abgerechnet = false AND bezahlt = false' ])) && (@expenses_unbezahlt.length > 0)
	  	if (@expenses_unbezahlt = Expense.find(:all, :order => "datum DESC", :conditions => ["user_id = "+current_user.id.to_s+" AND geloescht = false AND abgerechnet = false AND bezahlt = false AND datum >= '"+@year.to_s+"-"+@month.to_s+"-01' AND datum < '"+@next_year.to_s+"-"+@next_month.to_s+"-01'"])) && (@expenses_unbezahlt.length > 0)
		  	for expense in @expenses_unbezahlt
	          		@monat_netto_unbezahlt += expense.netto
	    	  		@monat_brutto_unbezahlt += expense.brutto
		  	end
		end
        
    end
    


    
  end

  def show
    @expense = Expense.find(params[:id])
  end

  def new
    @expense = Expense.new
    @expense.bezahlt = true
  end

  def create
    @expense = Expense.new(params[:expense])
    @expense.eintragsdatum = Date.today
    @expense.user_id = current_user.id
    #@expense.bezahlt = true
	if @expense.datum == nil
      @expense.datum = Date.today
    else
      d_monat = @expense.datum.strftime("%m")
      d_monatp = d_monat.to_i + 1
      d_jahr = @expense.datum.strftime("%Y")
      d_jahrp = d_jahr.to_i + 1
      dat = Date.strptime(d_jahr.to_i.to_s + '-' + d_monat.to_i.to_s + '-01')
      
      if d_monat.to_i == 12
        dat_end = Date.strptime(d_jahrp.to_s + '-01-01')
      else
        dat_end = Date.strptime(d_jahr.to_i.to_s + '-' + d_monatp.to_s + '-01')
      end
      
      if Statement.find_by_name(dat.to_s + ',' + dat_end.to_s)
        flash[:notice] = 'Datum liegt zu weit in der Vergangenheit.'
        bla =1
      end
    end
    if bla != 1
      if @expense.save
        flash[:notice] = 'Ausgabe wurde erfolgreich hinzugefügt.'
        redirect_to :action => 'list'
      else
        render :action => 'new'
      end
    else
      render :action => 'new'
    end

  end

  def edit
    @expense = Expense.find(params[:id])
  end

  def update
    @expense = Expense.find(params[:id])
    if @expense.update_attributes(params[:expense])
      flash[:notice] = 'Ausgabe wurde erfolgreich aktualisiert.'
      redirect_to :action => 'list'
      #redirect_to :action => 'show', :id => @expense
    else
      render :action => 'edit'
    end
  end

  def destroy
    #Expense.find(params[:id]).destroy
    @expense = Expense.find(params[:id])
    @expense.geloescht = true
    @expense.save
    flash[:notice] = 'Ausgabe wurde erfolgreich gelöscht.'
    redirect_to :action => 'list'
  end
end
