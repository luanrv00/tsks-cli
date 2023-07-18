require "tsks/storage"

module Tsks
  class Actions
    def self.update_tsks_with_user_id user_id
      current_tsks = Tsks::Storage.select_all

      for tsk in current_tsks
        Tsks::Storage.update_by({rowid: tsk[:rowid]}, {user_id: user_id})
      end
    end

    def self.update_server_for_removed_tsks token
      tsks_ids = Tsks::Storage.select_removed_tsk_ids

      if !tsks_ids.empty?
        for id in tsks_ids
          Tsks::Request.delete "/tsks/#{id}", token
        end
      end
      Tsks::Storage.delete_removed_tsks_ids
    end

    # TODO: write test
    def self.update_server_for_doing_tsks token
      tsks = Tsks::Storage.select_doing_tsks_not_synced
      puts "-------------------- doing tsks #{tsks.inspect}"

      if !tsks.empty?
        for current_tsk in tsks
          puts "-------------------- current_tsk #{current_tsk.inspect}"
          if current_tsk[:id]
            res = Tsks::Request.put "/tsks/#{current_tsk[:id]}", token, {tsk: {status: 'doing'}}
            puts "-------------------- res #{res.inspect}"
            @tsk = res[:tsk]
            puts "-------------------- PUT @tsk #{@tsk.inspect}"
            # puts "-------------------- PUT current_tsk #{current_tsk}"
            # puts "-------------------- PUTed current_tsk #{@tsk.inspect}"
          else
            res = Tsks::Request.post "/tsks", token, {tsk: current_tsk}
            puts "-------------------- res #{res.inspect}"
            @tsk = res[:tsk]
            puts "-------------------- POST @tsk #{@tsk.inspect}"
            # puts "-------------------- POST current_tsk #{current_tsk}"
            # puts "-------------------- POSTed current_tsk #{@tsk.inspect}"
          end

          Tsks::Storage.update @tsk[:id], {sync: @tsk[:sync], 
                                           updated_at: @tsk[:updated_at]}
        end
      end
    end

    def self.get_tsk_status status
      available_status = {
        todo: '-',
        done: '*',
        doing: '+',
        freezed: '!',
        archived: 'x',
      }

      available_status[status.to_sym]
    end
  end
end
