require 'fileutils'

module Server_Functions
    #Validates email
    def validate_email(email)
        first_check = false
        #Checks each character
        email.each_char do |letter|
            #Checks for @
            if letter == "@"
                first_check = true
            end
            #Checks for a dot 
            if first_check
                if letter == "."
                    return true
                end
            end 
        end
        return false
    end

    # Takes an array as input and converts it into a string of values or elements for SQL
    def arr_to_str(input, mod='')
        str = "("
        input.each do |item|
            if item.is_a?(String)
                str+= mod + item + mod + ','
            else
                str+= item.to_s + ','
            end
        end
        str[-1] = ')'
        return str
    end

    #Generates a text id
    def generate_text_id(number)
        charset = Array('A'..'Z') + Array('a'..'z') + Array('0'..'9') + ['_', '-']
        return Array.new(number) { charset.sample }.join
    end

    def image_to_dir(image, dest='img')
        #Generates text id for img
        id = generate_text_id(15)
        filename = id + File.extname(image[:filename])
        tempfile = image[:tempfile]
        target = "public/img/#{filename}"
        #Writes file to target
        File.open(target, 'wb') {|f| f.write tempfile.read }
        return id
    end 

    def time_since_created(time_created)
        str = "ERROR"
        age = (Time.now.to_i - time_created.to_i)
        case age
        when 0..60
            str = "Posted just now" 
            return str
        when 60..3600
            str = "Posted #{age / 60} minutes ago"
            return str
        when 3600..86400
            str = "Posted #{age / 3600} hours ago"
            return str
        when 86400..(86400 * 30)
            str = "Posted #{age / 86400} days ago" 
            return str
        when (86400 * 30)..(86400 * 365)
            str = "Posted #{age / (86400 * 30)} months ago"
            return str
        else
            str = "Posted #{age / (86400 * 365)} years ago"
            return str
        end
        return str
    end
end