RedmineApp::Application.routes.draw do
  get 'sla/dashboard', to: 'sla_dashboard#index', as: 'sla_dashboard'
  get 'admin/sla', to: 'sla_admin#index', as: 'sla_admin'

  resources :sla_project_settings, except: [:index, :show]
  resources :sla_holidays, only: [:create, :destroy]
  resources :sla_rules, except: [:show]

  get 'projects/:project_id/sla', to: 'sla_projects#show', as: 'project_sla'
end
