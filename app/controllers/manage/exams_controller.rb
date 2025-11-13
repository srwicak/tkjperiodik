class Manage::ExamsController < ApplicationController
  before_action -> { check_admin_status(redirect: true) }

  def index

  end

  def show
    
  end

  def data
    @exams = Exam.all
  end
end
