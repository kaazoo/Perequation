class GainsController < ApplicationController
  
  # class for display of money values:
  require 'more_money'
  MoreMoney::Money.add_currency({:code => 'EUR', :description => 'euro'})
  
  # user login:
  include AuthenticatedSystem
  before_filter :login_required
  
  # actions for list:
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
  
  # sum of netto values:
  def auswahl_summe
  	@summe_netto = @summe_brutto = 0
  	for aw in params[:auswahl] do
  	  if aw[1].to_i == 1
  	    gain = Gain.find(aw[0].to_i)
  	    @summe_netto += gain.netto
  	    @summe_brutto += gain.brutto
  	  end
  	end
  	render :partial => 'summe'
  end
  
  def auswahl_abrechnung
    puts params
    
    # send selection to partial view:
    if params[:auswahl]
      @nicht_bezahlt = Array.new
      @bezahlt = Array.new
      @summe_netto = @summe_brutto = 0
      
      for aw in params[:auswahl] do
  	    if aw[1].to_i == 1
  	      gain = Gain.find(aw[0].to_i)
  	      # already paid?
  	      if gain.bezahlt == true
            @summe_netto += gain.netto
            @summe_brutto += gain.brutto
            puts @bezahlt << gain.id
          else
            puts @nicht_bezahlt << gain.id
          end
  	    end
  	  end
  	  
      render :partial => 'abrechnung'
      
    # data comes back from flash variable of view:
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
  	    # TODO: create database entries
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
  	  end
  	  
      # bestehende abrechnung erweitern:
      if (@summe_netto != 0) && (@abrechnung_bestehend != nil) && (@abrechnung_bestehend != "")
        statement = Statement.find(@abrechnung_bestehend)
  	    @abrechnung_name = statement.name
  	    statement.einnahmen_netto = @summe_netto
  	    statement.einnahmen_brutto = @summe_brutto
  	    statement.gewinn_netto = statement.einnahmen_netto - statement.ausgaben_netto
  	    statement.gewinn_brutto = statement.einnahmen_brutto - statement.ausgaben_brutto
        statement.save
        
        for bz in @bezahlt do
  	      gain = Gain.find(bz.to_i)
	  	  gain.statement_id = statement.id
	  	  gain.abgerechnet = true
	  	  gain.save
  	    end  	  
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
      	@gains = Gain.paginate :page => params[:page], :order => "datum DESC", :conditions => ["geloescht = ? AND bezahlt = ?", false, true]
      	# summe des aktuellen monats:
	  	@monat_netto = @monat_brutto = 0
	  	for gain in @gains
  	    	if gain.datum.month == Date.today.month
          		@monat_netto += gain.netto
    	  		@monat_brutto += gain.brutto
  	    	end
	  	end
        
      when "future"
        @gains = Gain.paginate :page => params[:page], :order => "datum DESC", :conditions => ['geloescht = ? and abgerechnet = ? and bezahlt = ?', false, false, false]
      	# summe des aktuellen monats:
	  	@future_netto = @future_brutto = 0
	  	for gain in @gains
        	@future_netto += gain.netto
    		@future_brutto += gain.brutto
	  	end
        
      else
      	@gains = Gain.paginate :page => params[:page], :order => "datum DESC", :conditions => ['user_id = '+current_user.id.to_s+' and geloescht = ? and abgerechnet = ?', false, false]
      	
      	# summen des aktuellen monats:
      	
      	@monat_netto_bezahlt = @monat_brutto_bezahlt = 0
      	if (@gains_bezahlt = Gain.find(:all, :order => "datum DESC", :conditions => ['user_id = '+current_user.id.to_s+' and geloescht = ? AND abgerechnet = ? AND bezahlt = ?', false, false, true ])) && (@gains_bezahlt.length > 0)
		  	for gain in @gains_bezahlt
	  	    	if gain.datum.month == Date.today.month
	          		@monat_netto_bezahlt += gain.netto
	    	  		@monat_brutto_bezahlt += gain.brutto
	  	    	end
		  	end
		end
	  	
	  	@monat_netto_unbezahlt = @monat_brutto_unbezahlt = 0
	  	if (@gains_unbezahlt = Gain.find(:all, :order => "datum DESC", :conditions => ['user_id = '+current_user.id.to_s+' and geloescht = ? AND abgerechnet = ? AND bezahlt = ?', false, false, false ])) && (@gains_unbezahlt.length > 0)
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
