module BaTags
  include Radiant::Taggable

  tag "ba" do |tag|
    tag.locals.site_user = controller.__send__(:current_site_user) if self.respond_to?(:controller) && controller.respond_to?(:current_site_user)
    tag.expand
  end

  desc %{
    Tags inside this tag refer to the attendance of the current site_user.
  }
  tag "ba:attendance" do |tag|
    tag.locals.attendance = happening_page.attendance(tag.locals.site_user)
    tag.expand
  end

  desc %{
    Renders the contained elements only if the current site_user has NOT signed up for the happening
  }
  tag "ba:attendance:unless" do |tag|
    tag.expand unless tag.locals.attendance
  end

  desc %{
    Renders the contained elements only if the current site_user has signed up for the happening
  }
  tag "ba:attendance:if" do |tag|
    tag.expand if tag.locals.attendance
  end

  desc %{
    Renders the price (currency and amount) of the signed in site_user's attendance
    to the happening.
    
    *Usage:* 
    <pre><code><r:ba:attendance:price [free="free_text"]/></code></pre>
  }
  tag "ba:attendance:price" do |tag|
    price = tag.locals.attendance.actual_price
    free = tag.attr['free'] || '0'
    price ? "#{price.currency} #{price.amount}" : free
  end

  desc %{
    Tags inside this tag refer to the presentations of the current site_user, relative to the happening.
  }
  tag "ba:attendance:presentations" do |tag|
    tag.locals.presentation_pages = tag.locals.attendance.presentation_pages
    tag.expand
  end

  desc %{
    Renders the contained elements only if the current site_user has NOT submitted any presentations
  }
  tag "ba:attendance:presentations:unless" do |tag|
    tag.expand unless !tag.locals.presentation_pages.empty?
  end

  desc %{
    Renders the contained elements only if the current site_user has submitted any presentations
  }
  tag "ba:attendance:presentations:if" do |tag|
    tag.expand if !tag.locals.presentation_pages.empty?
  end

  desc %{
    Cycles through each of the current site_user's presentation pages. Works just like r:children:each.
  }
  tag "ba:attendance:presentations:each" do |tag|
    result = []
    tag.locals.presentation_pages.each do |presentation_page|
      tag.locals.page = presentation_page
      tag.locals.child = presentation_page
      result << tag.expand
    end
    result
  end

  desc "Displays event details as hCal" 
  tag "ba:hcal" do |tag|
    description = tag.attr['description']
    location = tag.attr['location']
    hp = happening_page

    %{<div class="vevent">
  <h3 class="summary"><a href="#{url}" class="url">#{title}</a></h3>
  <p class="description">#{description}</p>
  <p>
    <abbr class="dtstart" title="#{hp.starts_at.iso8601}">#{hp.starts_at.to_s(:long)}</abbr>
  </p>
  <p><span class="location">#{location}</span></p>
</div>}
  end

  desc %{
    Renders a signup form for the happening.
    This tag can only be used on attendances/* parts of a Happening page.
    
    NOTE: You MUST make sure the layout used for your page includes the prototype.js
    javascript in the head section:
    
    <pre><code><script src="/javascripts/prototype.js" type="text/javascript"></script></code></pre>
  }
  tag "ba:new_attendance_form" do |tag|
    render_partial('attendances/new')
  end

  desc %{
    Renders a form to edit an existing attendance.
    This tag can be used on the attendances/already part of a Happening page.
    
    NOTE: You MUST make sure the layout used for your page includes the prototype.js
    javascript in the head section:
    
    <pre><code><script src="/javascripts/prototype.js" type="text/javascript"></script></code></pre>
  }
  tag "ba:attendance:form" do |tag|
    render_partial('attendances/edit')
  end
  
  def render_partial(partial)
    page = self
    url = page.url.split('/').reject{|e| e.blank?}
    controller.instance_eval do
      render :locals => {:page => page, :url => url}, :partial => partial
    end
  end
  
  desc %{
    Displays the name of the logged in site_user
  }
  tag "ba:site_user_name" do |tag|
    tag.locals.site_user.name
  end

  desc %{
    Tags inside this tag refer to the program of the happening.

    *Usage:*
    <pre><code>
    <r:ba:program empty_text="To be announced">
    <table>
      <tr>
        <td>13:00-13:45</td>
        <td><r:presentation slot="1000" empty_text="Keynote. Speaker to be announced later."/></td>
      </tr>
      <tr>
        <td>14:00-14:45</td>
        <td><r:presentation slot="1001" /></td>
      </tr>
      <tr>
        <td>15:00-15:45</td>
        <td><r:presentation slot="1002" /></td>
      </tr>
    </table>
    </r:ba:program>
    </code></pre>
    
    The empty_text value will be displayed when there is no assigned happening.
    This can be overridden in presentation tags underneath.
  }
  tag "ba:program" do |tag|
    tag.locals.empty_text = tag.attr["empty_text"] || "TBA"
    tag.expand
  end

  desc %{
    Renders an empty slot in the program, or the presentation title if one has been assigned
    in the program admin UI. (Coming soon: Rendering of links instead of just the title)
    
    The slot value must be unique across all the program pages within a happening.
    The empty_text value will be displayed when there is no assigned happening, and
    overrides any default value you may have set in the parent tag.
  }
  tag "ba:program:presentation" do |tag|
    program_slot = tag.attr["slot"]
    presentation_page = presentations_page.presentation_pages.with_slot(program_slot)
    if presentation_page
      "<div class=\"program slot\" id=\"slot_#{program_slot}\"><div class=\"presentation\" id=\"presentation_#{presentation_page.id}\">#{presentation_page.title}</div></div>"
    else
      content = tag.attr["empty_text"] || tag.locals.empty_text
      "<div class=\"program slot\" id=\"slot_#{program_slot}\"><div class=\"empty\">#{content}</div></div>"
    end
  end

  tag "ba:presentations" do |tag|
    tag.expand
  end
  
  desc %{Loops over all the draft presentations for a happening}
  tag "ba:presentations:each_draft" do |tag|
    result = []
    happening_page.presentation_pages.drafts.each do |presentation_page|
      tag.locals.page = presentation_page
      tag.locals.child = presentation_page
      result << tag.expand
    end
    result
  end

  desc %{The id of a page}
  tag "ba:presentations:each_draft:id" do |tag|
    tag.locals.page.id
  end

  [:name, :email].each do |field|
    desc %{The #{field} of the recipient. 
    
    This tag can only be used in the body section of email parts} 
    tag "ba:email:site_user:#{field}" do |tag|
      globals.site_user.__send__(field)
    end
  end
end