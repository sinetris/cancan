module CanCan
  # This module is automatically included into all Active Record models.
  module ActiveRecordAdditions
    module ClassMethods
      # Returns a scope which fetches only the records that the passed ability
      # can perform a given action on. The action defaults to :read. This
      # is usually called from a controller and passed the +current_ability+.
      #
      #   @articles = Article.accessible_by(current_ability)
      #
      # Here only the articles which the user is able to read will be returned.
      # If the user does not have permission to read any articles then an empty
      # result is returned. Since this is a scope it can be combined with any
      # other scopes or pagination.
      #
      # An alternative action can optionally be passed as a second argument.
      #
      #   @articles = Article.accessible_by(current_ability, :update)
      #
      # Here only the articles which the user can update are returned. This
      # internally uses Ability#conditions method, see that for more information.
      def accessible_by(ability, action = :read)
        query = ability.query(action, self)
        if respond_to?(:where) && respond_to?(:joins)
          sql_query = joins(query.joins).to_sql
          joins_re = /INNER JOIN [\"`](.+)[\"`] ON/
          m = joins_re.match(sql_query)
          if m && m.captures[0]
            query_conditions = {}
            query.conditions.each_pair {|key, value|
              if query.joins.to_s == key.to_s
                query_conditions[m.captures[0]] = value
              else
                query_conditions[key] = value
              end
            }
          else
            query_conditions = query.conditions
          end
          joins(query.joins).where(query_conditions)
        else
          scoped(:conditions => query.conditions, :joins => query.joins)
        end
      end
    end

    def self.included(base)
      base.extend ClassMethods
    end
  end
end

if defined? ActiveRecord
  ActiveRecord::Base.class_eval do
    include CanCan::ActiveRecordAdditions
  end
end
