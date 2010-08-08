# deutsche Übersetzung der Monatesnamen:
#class Date
# MONTHNAMES.replace([nil] + %w(Januar Februar März April Mai Juni Juli August September Oktober November Dezember) )
#end


class GainsController < ApplicationController
  
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
  	    gain = Gain.find(aw[0].to_i)
  	    @summe_netto += gain.netto
  	    @summe_brutto += gain.brutto
  	  end
  	end
  	#@summe_netto = "Summe: "+summe_netto.to_s+" (Netto)"
  	#@summe_brutto = "Summe: "+summe_brutto.to_s+" (Brutto)"
  	#index
  	render :partial => 'summe'
  end
  
  def auswahl_abrechnung
    puts params
    
    # auswahl an partial-view senden:
    if params[:auswahl]
    @nicht_bezahlt = Array.new
    @bezahlt = Array.new
    #i = 0
    
    @summe_netto = @summe_brutto = 0
    for aw in params[:auswahl] do
  	  if aw[1].to_i == 1
  	    gain = Gain.find(aw[0].to_i)
  	    # schon bezahlt?
  	    if gain.bezahlt == true
          @summe_netto += gain.netto
          @summe_brutto += gain.brutto
          puts @bezahlt << gain.id
        else
          puts @nicht_bezahlt << gain.id
          #puts i = i + 1
        end
  	  end
  	end
  	#if (@summe_netto == 0) || (@summe_brutto == 0)
  	#  flash[:ajax_hinweis] = "Bitte Eintr&auml;ge aus der Liste markieren!"
  	#end

     
      #@auswahl = params[:auswahl]
      #puts @auswahl
      render :partial => 'abrechnung'
    # daten kommen aus flash-speicher vom view zurück:
    else
      #puts flash[:auswahl]
      #@summe_netto = @summe_brutto = 0
  	  #for aw in flash[:auswahl] do
  	  #  if aw[1].to_i == 1
  	  #    gain = Gain.find(aw[0].to_i)
  	  #    @summe_netto += gain.netto
  	  #    @summe_brutto += gain.brutto
  	  #  end
  	  #end
  	  
  	  #if (@summe_netto == 0) || (@summe_brutto == 0)
  	  #  flash[:hinweis] = "Bitte Eintr&auml;ge aus der Liste markieren!"
  	  #end
  	  #if params[:abrechnung][:name] == ""
  	  #  flash[:hinweis2] = "Bitte einen Namen angeben!"
  	  #end
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
  	    statement.einnahmen_netto = @summe_netto
  	    statement.einnahmen_brutto = @summe_brutto
  	    statement.ausgaben_netto = 0
  	    statement.ausgaben_brutto = 0
  	    statement.gewinn_netto = 0
  	    statement.gewinn_brutto = 0
  	    statement.erstellungsdatum = Date.today
        statement.save
        
        for bz in @bezahlt do
  	      gain = Gain.find(bz.to_i)
	  	  gain.statement_id = statement.id
	  	  gain.abgerechnet = true
	  	  gain.save
  	    end
  	  
        #redirect_to :action => 'list/all'
  	  end
      # bestehende abrechnung erweitern:
      if (@summe_netto != 0) && (@abrechnung_bestehend != nil) && (@abrechnung_bestehend != "")
        statement = Statement.find(@abrechnung_bestehend)
  	    @abrechnung_name = statement.name
  	    statement.einnahmen_netto = @summe_netto
  	    statement.einnahmen_brutto = @summe_brutto
  	    #statement.ausgaben_netto = 0
  	    #statement.ausgaben_brutto = 0
  	    statement.gewinn_netto = statement.einnahmen_netto - statement.ausgaben_netto
  	    statement.gewinn_brutto = statement.einnahmen_brutto - statement.ausgaben_brutto
  	    #statement.erstellungsdatum = Date.today
        statement.save
        
        for bz in @bezahlt do
  	      gain = Gain.find(bz.to_i)
	  	  gain.statement_id = statement.id
	  	  gain.abgerechnet = true
	  	  gain.save
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
    # alle oder nur eigene einträge anzeigen:
    case(params[:id])
      when "all"
      	@gain_pages, @gains = paginate :gains, :per_page => 30, :order => "datum DESC", :conditions => ["geloescht = false AND bezahlt = true"]
      	# summe des aktuellen monats:
	  	@monat_netto = @monat_brutto = 0
	  	for gain in @gains
  	    	if gain.datum.month == Date.today.month
          		@monat_netto += gain.netto
    	  		@monat_brutto += gain.brutto
  	    	end
	  	end
        
      when "future"
      	@gain_pages, @gains = paginate :gains, :per_page => 30, :order => "datum DESC", :conditions => ['geloescht = false and abgerechnet = false and bezahlt = false']
      	# summe des aktuellen monats:
	  	@future_netto = @future_brutto = 0
	  	for gain in @gains
        	@future_netto += gain.netto
    		@future_brutto += gain.brutto
	  	end
        
      else
      	@gain_pages, @gains = paginate :gains, :per_page => 30, :order => "datum DESC", :conditions => ['user_id = '+current_user.id.to_s+' and geloescht = false and abgerechnet = false']
      	
      	# summen des aktuellen monats:
      	
      	@monat_netto_bezahlt = @monat_brutto_bezahlt = 0
      	if (@gains_bezahlt = Gain.find(:all, :order => "datum DESC", :conditions => ['user_id = '+current_user.id.to_s+' and geloescht = false AND abgerechnet = false AND bezahlt = true' ])) && (@gains_bezahlt.length > 0)
		  	for gain in @gains_bezahlt
	  	    	if gain.datum.month == Date.today.month
	          		@monat_netto_bezahlt += gain.netto
	    	  		@monat_brutto_bezahlt += gain.brutto
	  	    	end
		  	end
		end
	  	
	  	@monat_netto_unbezahlt = @monat_brutto_unbezahlt = 0
	  	if (@gains_unbezahlt = Gain.find(:all, :order => "datum DESC", :conditions => ['user_id = '+current_user.id.to_s+' and geloescht = false AND abgerechnet = false AND bezahlt = false' ])) && (@gains_unbezahlt.length > 0)
		  	for gain in @gains_unbezahlt
	  	    	if gain.datum.month == Date.today.month
	          		@monat_netto_unbezahlt += gain.netto
	    	  		@monat_brutto_unbezahlt += gain.brutto
	  	    	end
		  	end
		end
        
    end
    
     
  
  end

  def show
    @gain = Gain.find(params[:id])
  end

  def new
    @gain = Gain.new
  end

  def create
    @gain = Gain.new(params[:gain])
    @gain.eintragsdatum = Date.today
    
    # datum auf heute setzen
    if @gain.datum == nil
      @gain.datum = Date.today
    else
    
      # datum von eingabe und nicht von db holen 
      puts d_jahr = params[:gain]["datum(1i)"]
      puts d_monat = params[:gain]["datum(2i)"]
      puts params[:gain]["datum(3i)"]
      
      #d_monat = @gain.datum.strftime("%m")
      d_monatp = d_monat.to_i + 1
      #d_jahr = @gain.datum.strftime("%Y")
      d_jahrp = d_jahr.to_i + 1
      dat = Date.strptime(d_jahr.to_i.to_s + '-' + d_monat.to_i.to_s + '-01')
      
      if d_monat.to_i == 12
        dat_end = Date.strptime(d_jahrp.to_s + '-01-01')
      else
        dat_end = Date.strptime(d_jahr.to_i.to_s + '-' + d_monatp.to_s + '-01')
      end
      if Statement.find_by_name(dat.to_s + ',' + dat_end.to_s)
        flash[:notice] = 'Datum liegt zu weit in der Vergangenheit.'
        bla = 1
      end
    end
    @gain.user_id = current_user.id
    if bla != 1
      if @gain.save
        flash[:notice] = 'Einnahme wurde erfolgreich hinzugefügt.'
        redirect_to :action => 'list' and return
      else
        render :action => 'new' and return
      end
    else
        render :action => 'new' and return
    end
  end

  def edit
    @gain = Gain.find(params[:id])
  end

  def update
    @gain = Gain.find(params[:id])
    
    # datum auf heute setzen
    if @gain.datum == nil
      @gain.datum = Date.today
    else
    
      # datum von eingabe und nicht von db holen 
      puts d_jahr = params[:gain]["datum(1i)"]
      puts d_monat = params[:gain]["datum(2i)"]
      puts params[:gain]["datum(3i)"]
      
      #d_monat = @gain.datum.strftime("%m")
      d_monatp = d_monat.to_i + 1
      #d_jahr = @gain.datum.strftime("%Y")
      d_jahrp = d_jahr.to_i + 1
      dat = Date.strptime(d_jahr.to_i.to_s + '-' + d_monat.to_i.to_s + '-01')
      
      if d_monat.to_i == 12
        dat_end = Date.strptime(d_jahrp.to_s + '-01-01')
      else
        dat_end = Date.strptime(d_jahr.to_i.to_s + '-' + d_monatp.to_s + '-01')
      end
      # user will eintrag als bezahlt markieren, liegt aber zu weit in der vergangenheit
      if((Statement.find_by_name(dat.to_s + ',' + dat_end.to_s)) && (params[:gain]["bezahlt"] == true))
        flash[:notice] = 'Datum liegt zu weit in der Vergangenheit.'
        bla =1
      end
    end
    if bla != 1
      if @gain.update_attributes(params[:gain])
        flash[:notice] = 'Einnahme wurde erfolgreich aktualisiert.'
        redirect_to :action => 'list'
        #redirect_to :action => 'show', :id => @gain
      else
        render :action => 'edit'
      end
    else
      render :action => 'edit'
    end
  end

  def destroy
    #Gain.find(params[:id]).destroy
    @gain = Gain.find(params[:id])
    @gain.geloescht = true
    @gain.save
    flash[:notice] = 'Einnahme wurde erfolgreich gelöscht.'
    redirect_to :action => 'list'
  end
end