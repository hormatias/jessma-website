#!/usr/bin/env ruby
# frozen_string_literal: true

# Punto de entrada portable (Mac, Windows, Linux) para tareas Jekyll.
# Uso: ruby start.rb <comando> [argumentos extra para jekyll/bundle]

ROOT = __dir__
Dir.chdir(ROOT)

COMMANDS = %w[install dev build].freeze

def usage
  puts <<~MSG
    Uso: start.rb <comando> [opciones]

    Comandos:
      install    Instala gemas (bundle install)
      dev        Servidor de desarrollo (jekyll serve)
      build      Genera el sitio estático (jekyll build)

    Los argumentos extra se pasan a bundle/jekyll (p. ej. dev --port 4001).

    En Mac/Linux:  ./start dev
    En Windows:    start.bat dev   o   ruby start.rb dev
  MSG
end

def run!(argv)
  success = system(*argv)
  exit(1) unless success
end

command = ARGV.shift

if command.nil? || %w[-h --help help].include?(command)
  usage
  exit(command.nil? ? 1 : 0)
end

unless COMMANDS.include?(command)
  warn "Comando desconocido: #{command}\n"
  usage
  exit 1
end

case command
when 'install'
  run!(['bundle', 'install', *ARGV])
when 'dev'
  # exec deja que Ctrl+C llegue directo a Jekyll
  exec('bundle', 'exec', 'jekyll', 'serve', *ARGV)
when 'build'
  run!(['bundle', 'exec', 'jekyll', 'build', *ARGV])
end
