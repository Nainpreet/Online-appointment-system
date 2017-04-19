#
class AppointmentsController < ApplicationController
  def index
    @records = Appointment.where.not(status: ['Completed', 'Cancel', 'Reject'])
    if current_user.role == 'Patient'
      @appointments = @records.where('user_id = ? ', current_user.id)
    else
      @appointments = @records.where(doctor_id: Doctor.find_by(user_id: current_user.id).id )
    end
  end

  def appointment_history
    @records = Appointment.where(status: ['Completed', 'Cancel', 'Reject'])
    if current_user.role == 'Patient'
      @history = @records.where('user_id = ? ', current_user.id)
    else
      @history = @records.where(doctor_id: Doctor.find_by(user_id: current_user.id).id )
    end
  end

  def appointment_status
    @id = Appointment.find(params[:id])
    @status = @id.update_attributes(status: params[:status])
    byebug
    if params[:status] == 'Completed'
      UserMailer.appointment_completed(@id.user, @id.doctor.user.name, @id.app_date).deliver
      redirect_to appointment_history_path
    elsif params[:status] == 'Reject'
      redirect_to appointment_history_path
      UserMailer.appointment_reject(@id.user, @id.doctor.user.name).deliver
    elsif params[:status] == 'Follow Up'
      redirect_to edit_appointment_path(params[:id])
    elsif params[:status] == 'Accept'
      UserMailer.appointment_confirmation(@id.user, @id.doctor.user.name).deliver
      redirect_to appointments_path
    end
  end

  def appointment_cancel
    @id = Appointment.find(params[:id])
    if Time.now + 1.day < @id.app_date
      flash[:notice] = "Your appointment has been cancel"
      Appointment.delete(@id)
      UserMailer.appointment_cancel(@id.user, @id.doctor.user.name).deliver
      redirect_to appointments_path
    else
      flash[:notice] = "You can't cancel appointment one day before"
      redirect_to appointments_path
    end
  end

  def new
    @appointment = Appointment.new
  end

  def new1
    @doctors = Doctor.find(params[:format])
  end

  def create
    @doctors =  Doctor.find_by_department_id(params[:appointment][:department_id])
    @id = Doctor.find_by_user_id(params[:appointment][:doctor_id])
    if @doctors
      if @doctors.user.name == @id.user.name
        redirect_to new1_appointment_path(@doctors)
      else
        flash[:alert] = 'There id no doctor to corressponding department'
        redirect_to new_appointment_path
      end
    else
      redirect_to new_appointment_path
    end
  end

  def create_appointment
    @appointment = Appointment.create(:user_id => current_user.id,:doctor_id => params[:doctor_id] ,:app_date => params[:days], :date => Date.today, :time_slots => params[:time_slots], :symptoms => params[:symptoms])
    if @appointment.save
      redirect_to appointment_path(@appointment)
    else
      redirect_to new1_appointment_path(@doctors)
    end
  end

  def show
    @appointment = Appointment.find(params[:id])
  end

  def edit
    @appointment = Appointment.find(params[:id])
  end

  def update
    @appointment = Appointment.find(params[:id])
    if @appointment.update_attributes(:symptoms => params[:appointment][:symptoms], :medications => params[:appointment][:medications], :app_date => params[:days])
        redirect_to appointments_path
        UserMailer.appointment_follow(@appointment.user, @appointment.doctor.user.name, @appointment.app_date).deliver
    else
        render 'edit'
    end
  end

end
