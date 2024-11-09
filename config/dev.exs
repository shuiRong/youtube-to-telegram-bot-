import Config

IO.puts("config/dev.exs")
# 在开发环境导入敏感配置
if File.exists?("config/dev.secret.exs") do
  IO.puts("导入敏感配置")
  import_config "dev.secret.exs"
end
