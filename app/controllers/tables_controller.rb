class TablesController < ApplicationController
  before_action :require_login
  before_action :set_table, only: [ :edit, :update, :destroy ]

  def index
    @tables = Table.all
  end

  def new
    @table = Table.new
  end

  def create
    @table = Table.new(table_params)
    if @table.save
      redirect_to tables_path, notice: "Table created successfully."
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
    @table.destroy
    redirect_to tables_path, notice: "Table deleted."
  end

  private

  def set_table
    @table = Table.find(params[:id])
  end

  def table_params
    params.require(:table).permit(:name, :seats)
  end
end
