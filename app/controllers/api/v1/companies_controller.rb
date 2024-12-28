class Api::V1::CompaniesController < ApplicationController
  def index
    @companies = Company.includes(:addresses)
    render :index
  end

  def show
    @company = Company.find(params[:id])
    render :show
  rescue ActiveRecord::RecordNotFound
    @title = "Company Not Found"
    @status = 404
    render :error_response, status: :not_found
  end

  def create
    @company = Company.new(company_params)

    if @company.save
      render :create, status: :created
    else
      @title = "Validation Failed"
      @status = 422
      render :error_response, status: :unprocessable_entity
    end
  end

  private

  def company_params
    params.require(:company).permit(:name, :registration_number, addresses_attributes: %i[street city postal_code country company])
  end
end
