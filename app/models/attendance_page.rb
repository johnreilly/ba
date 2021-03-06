require 'barby'
require 'barby/outputter/png_outputter'
require 'prawn'
require 'digest/md5'

class AttendancePage < Page
  before_validation_on_create :create_default_content

  def cache?
    false
  end

  def create_default_content
    self.slug = 'attendance'
    self.breadcrumb = self.title = 'Attendance'
    self.status = Status[:published]
    parts << PagePart.new(:name => 'body', :content => read_file('default_attendance_part.html'))
  end

  def find_by_url(url, live = true, clean = false)
    if url =~ %r{^#{ self.url }(.+)/$}
      @special_slug = $1
      self
    else
      super
    end
  end

  def process(request, response)
    @site_user = controller.current_site_user
    @attendance = happening_page.attendance(@site_user)

    if @attendance
      if request.post?
        if update_attendance(request.parameters)
          controller.redirect_to(self.url)
        else
          super
        end
      else
        if @special_slug == 'ticket'
          controller.send :send_data, @attendance.ticket.render, :type => 'application/pdf', :filename => 'smidig2008-billett.pdf'
        else
          super
        end
      end
    else
      # Nothing allowed here unless we're signed up
      if @site_user
        controller.redirect_to(happening_page.signup_page.url)
      else
        controller.session[:return_to] = url
        login_page = LoginPage.find(:first)
        controller.redirect_to(login_page.url)
      end
    end
  end
  
  def update_attendance(params)
    @attendance.update_attributes(params[:attendance])
  end
end