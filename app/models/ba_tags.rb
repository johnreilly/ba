module BaTags
  include Radiant::Taggable

  tag "ba" do |tag|
    tag.locals.site_user = controller.__send__(:current_site_user) if self.respond_to?(:controller) && controller.respond_to?(:current_site_user)
    tag.expand
  end

  desc %{
    Renders a signup form for the happening.
    This tag can only be used on attendances/* parts of a Happening page.
    
    NOTE: If you want to automatically show/hide the presentation section in the default signup form
    you MUST make sure the layout used for your page includes the prototype.js
    javascript in the head section:
    
    <pre><code><script src="/javascripts/prototype.js" type="text/javascript"></script></code></pre>
  }
  tag "ba:signup_form" do |tag|
    result = []
    result << %{<form action="#{controller.send(:attendance_path, :url => url.split('/').reject{|e| e.blank?})}" method="post">}
    result << tag.expand
    result << "</form>"
    result
  end

  ['input', 'textarea'].each do |f|
    d = {
      'input'    => ['an input field', '<r:ba:input object="site_user" field="name" type="text" />', '/>'],
      'textarea' => ['a text area', '<r:ba:textarea object="site_user" field="name" />', '></textarea>']
    }
    
    desc %{
      Renders #{d[f][0]} that is bound to a certain object's field/attribute/column. Handy for
      forms, because it automatically sets the value, name and id attributes of the element.
    
      *Usage:*
      <pre><code>
      #{d[f][1]}
      </code></pre>    

      This will render the following (if Aslak Hellesøy's signup fails):

      <pre><code>
      <input name="site_user[email]" value="Aslak Hellesøy" id="site_user_name" type="text" /><span class="error">has already been taken</span>
      </code></pre>
    
      Any other attributes passed to this tag will be passed on to the rendered input element.
    }
    tag "ba:#{f}" do |tag|
      object_name = tag.attr.delete('object')
      field_name  = tag.attr.delete('field')
      id          = tag.attr.delete('id') || "#{object_name}_#{field_name}"
      object = controller.instance_variable_get("@#{object_name}")
      error_msg = nil
      if object
        field_value = object.__send__(field_name)
        if object.respond_to?(:errors) && object.errors.on(field_name)
          tag.attr['class'] ||= ''
          tag.attr['class'] << ' error'
          tag.attr['class'].strip!
          error_msg = %{ <span class="error">#{object.errors.on(field_name)}</span>}
        end
      else
        field_value = nil
      end
      attrs = tag.attr.inject('') { |s, (k, v)| s << %{#{k.downcase}="#{v}" } }.strip
      %{<#{f} id="#{id}" name="#{object_name}[#{field_name}]" value="#{field_value}" #{attrs}#{d[f][2]}#{error_msg}}
    end
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
    if tag.locals.attendance
      tag.locals.presentation_pages = tag.locals.attendance.presentation_pages
      tag.expand
    end
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

  desc %{Returns a parameter from the request. Useful for redesplaying values in failed
    form submissions like login. If used with a value, the content inside will be rendered
    if the value matches. Useful for checkboxes.

    *Usage:*
    <pre><code>
    <r:ba:request_param name="email" />
    </code></pre>
    
    Or inside an input field of type checkbox...
    
    <pre><code>
    <r:ba:request_param name="remember_me" value="1">checked="checked" </r:ba:request_param>
    </code></pre>
  }
  tag "ba:request_param" do |tag|
    name = tag.attr['name']
    req_value = request.parameters[name]
    tag_value = tag.attr['value']
    if tag_value && tag_value == req_value
      tag.expand
    else
      req_value
    end
  end

end