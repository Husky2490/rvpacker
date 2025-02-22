=begin
This file contains significant portions of Psych 2.0.0 to modify behavior and to fix
bugs. The license follows:

Copyright 2009 Aaron Patterson, et al.

Permission is hereby granted, free of charge, to any person obtaining a copy of this 
software and associated documentation files (the 'Software'), to deal in the Software 
without restriction, including without limitation the rights to use, copy, modify, merge, 
publish, distribute, sublicense, and/or sell copies of the Software, and to permit 
persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or 
substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR 
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
DEALINGS IN THE SOFTWARE.
=end

gem 'psych', '>= 3.0.0', '<= 3.1.0'
require 'psych'

#if Psych::VERSION == '2.0.0'
  # Psych bugs: 
  #
# # 1) Psych has a bug where it stores an anchor to the YAML for an object, but indexes 
# # the reference by object_id. This doesn't keep the object alive, so if it gets garbage 
# # collected, Ruby might generate an object with the same object_id and try to generate a 
# # reference to the stored anchor. This monkey-patches the Registrar to keep the object 
# # alive so incorrect references aren't generated. The bug is also present in Psych 1.3.4
# # but there isn't a convenient way to patch that.
# #
  # 2) Psych also doesn't create references and anchors for classes that implement 
  # encode_with. This modifies dump_coder to handle that situation. 
  # 
  # Added two options:
  # :sort - sort hashes and instance variables for objects
  # :flow_classes - array of class types that will automatically emit with flow style
  #                 rather than block style
  module Psych
    module Visitors
      class YAMLTree < Psych::Visitors::Visitor
        
#         # Looks like this bug was fixed
#         class Registrar
#           old_initialize = self.instance_method(:initialize)
#           define_method(:initialize) do
#             old_initialize.bind(self).call
#             @obj_to_obj  = {}
#           end
# 
#           old_register = self.instance_method(:register)
#           define_method(:register) do |target, node|
#             old_register.bind(self).call(target, node)
#             @obj_to_obj[target.object_id] = target
#           end
#         end
        
        # Sort mod
        remove_method(:visit_Hash)
        def visit_Hash o
#           tag      = o.class == ::Hash ? nil : "!ruby/hash:#{o.class}"
#           implicit = !tag
# 
#           register(o, @emitter.start_mapping(nil, tag, implicit, Nodes::Mapping::BLOCK))
          if o.class == ::Hash
            register(o, @emitter.start_mapping(nil, nil, true, Psych::Nodes::Mapping::BLOCK))
            
            keys = o.keys
            keys = keys.sort if @options[:sort]
            keys.each do |k|
              accept k
              accept o[k]
            end

            @emitter.end_mapping
          else
            visit_hash_subclass o
          end
        end
        
        # Sort mod
        def visit_hash_subclass o
          ivars = o.instance_variables
          if ivars.any?
            tag = "!ruby/hash-with-ivars:#{o.class}"
            node = @emitter.start_mapping(nil, tag, false, Psych::Nodes::Mapping::BLOCK)
            register(o, node)
            
            # Dump the elements
            accept 'elements'
            @emitter.start_mapping nil, nil, true, Nodes::Mapping::BLOCK
            
#             o.each do |k,v|
#               accept k
#               accept v
#             end
            keys = o.keys
            keys = keys.sort if @options[:sort]
            keys.each do |k|
              accept k
              accept o[k]
            end
            @emitter.end_mapping
            
            # Dump the ivars
            accept 'ivars'
            @emitter.start_mapping nil, nil, true, Nodes::Mapping::BLOCK
#             o.instance_variables.each do |ivar|
#               accept ivar
#               accept o.instance_variable_get ivar
#             end
            ivars = o.instance_variables
            ivars = ivars.sort if @options[:sort]
            ivars.each do |ivar|
              accept ivar
              accept o.instance_variable_get ivar
            end
            @emitter.end_mapping
            
            @emitter.end_mapping
          else
            tag = "!ruby/hash:#{o.class}"
            node = @emitter.start_mapping(nil, tag, false, Psych::Nodes::Mapping::BLOCK)
            register(o, node)
#             o.each do |k,v|
#               accept k
#               accept v
#             end
            keys = o.keys
            keys = keys.sort if @options[:sort]
            keys.each do |k|
              accept k
              accept o[k]
            end
            @emitter.end_mapping
          end
        end
        
        # Flow mod
        remove_method(:visit_Object)
        def visit_Object o
          tag = Psych.dump_tags[o.class]
          unless tag
            klass = o.class == Object ? nil : o.class.name
            tag   = ['!ruby/object', klass].compact.join(':')
          end
          
          if @options[:flow_classes] && @options[:flow_classes].include?(o.class)
            style = Nodes::Mapping::FLOW
          else
            style = Nodes::Mapping::BLOCK
          end

          map = @emitter.start_mapping(nil, tag, false, style)
          register(o, map)

          dump_ivars o
          @emitter.end_mapping
        end
          
#         # Looks like this may have been fixed too
#         remove_method(:dump_coder)
#         def dump_coder o
#           @coders << o
#           tag = Psych.dump_tags[o.class]
#           unless tag
#             klass = o.class == Object ? nil : o.class.name
#             tag   = ['!ruby/object', klass].compact.join(':')
#           end
# 
#           c = Psych::Coder.new(tag)
#           o.encode_with(c)
#           register o, emit_coder(c)
#         end
        
        # Sort mod
        remove_method(:dump_ivars)
        def dump_ivars target
          ivars = target.instance_variables
          ivars = ivars.sort() if @options[:sort]

          ivars.each do |iv|
            @emitter.scalar("#{iv.to_s.sub(/^@/, '')}", nil, nil, true, false, Nodes::Scalar::ANY)
            accept target.instance_variable_get(iv)
          end
        end

      end
    end
  end
# else
#   warn "Warning: Psych 2.0.0 not detected" if $VERBOSE
# end
