# Test the topic_to_string function
Code.require_file("lib/server/pubsub/todo_pub_sub.ex")
Code.require_file("lib/server/pubsub/todo_pub_sub_topic.ex")

result = TodoPubSub.topic_to_string(:todo_updates)
IO.puts("Result for :todo_updates = #{inspect(result)}")

result2 = TodoPubSub.topic_to_string(:user_activity)  
IO.puts("Result for :user_activity = #{inspect(result2)}")

result3 = TodoPubSub.topic_to_string(:system_notifications)
IO.puts("Result for :system_notifications = #{inspect(result3)}")

# Test an invalid value to see what happens
try do
  result4 = TodoPubSub.topic_to_string(:invalid_topic)
  IO.puts("Result for :invalid_topic = #{inspect(result4)}")
rescue
  e -> IO.puts("Error for :invalid_topic: #{inspect(e)}")
end