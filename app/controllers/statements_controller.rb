class StatementsController < ApplicationController
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @statement_pages, @statements = paginate :statements, :per_page => 10
  end

  def show
    @statement = Statement.find(params[:id])
  end

  def new
    @statement = Statement.new
  end

  def create
    @statement = Statement.new(params[:statement])
    if @statement.save
      flash[:notice] = 'Statement was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @statement = Statement.find(params[:id])
  end

  def update
    @statement = Statement.find(params[:id])
    if @statement.update_attributes(params[:statement])
      flash[:notice] = 'Statement was successfully updated.'
      redirect_to :action => 'show', :id => @statement
    else
      render :action => 'edit'
    end
  end

  def destroy
    Statement.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
