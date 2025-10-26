class TablesController < ApplicationController
  include ActionView::RecordIdentifier
  before_action :require_login
  before_action :set_table, only: [ :edit, :update, :destroy ]

  def index
    @tables = Table.all
  end

  def new
    @table = Table.new
    @table.timeslots.build
  end

  def create
    @table = Table.new(table_params)

    if @table.save
      redirect_to tables_path, notice: "Table and Timeslot created successfully."
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @table.update(table_params)
      redirect_to tables_path, notice: "Table updated."
    else
      render :edit
    end
  end

  def destroy
    table_dom_id = dom_id(@table)
    @table.destroy

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(table_dom_id) }
      format.html { redirect_back fallback_location: tables_path, notice: "Table deleted." }
    end
  end

  private

  def set_table
    @table = Table.find(params[:id])
  end

  def table_params
    params.require(:table).permit(:quantity, :capacity, timeslots_attributes: [:id, :date, :start_time, :end_time, :_destroy])
  end
end
