# Test the topic_to_string function
result = TodoPubSub.topic_to_string(:todo_updates)
IO.puts("Result for :todo_updates = #{inspect(result)}")

result2 = TodoPubSub.topic_to_string(:user_activity)  
IO.puts("Result for :user_activity = #{inspect(result2)}")

result3 = TodoPubSub.topic_to_string(:system_notifications)
IO.puts("Result for :system_notifications = #{inspect(result3)}")
